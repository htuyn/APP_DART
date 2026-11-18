const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const dotenv = require('dotenv');
const { ethers } = require('ethers');

const contractsRoot = path.resolve(__dirname, '..');
dotenv.config({ path: path.join(contractsRoot, '.env') });

const RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.ISSUER_PRIVATE_KEY;
const API_KEY = process.env.RELAYER_API_KEY;
const PORT = Number(process.env.RELAYER_PORT || 8787);
const configPath = path.resolve(contractsRoot, '../lib/core/constants/blockchain_config.dart');
const configText = fs.readFileSync(configPath, 'utf8');
const configuredAddress = configText.match(/contractAddress\s*=\s*'([^']+)'/)?.[1];
const environmentAddress = process.env.CONTRACT_ADDRESS;
const hasValidEnvironmentAddress = environmentAddress && ethers.isAddress(environmentAddress);
const CONTRACT_ADDRESS = hasValidEnvironmentAddress ? environmentAddress : configuredAddress;
if (environmentAddress && !hasValidEnvironmentAddress) {
  console.warn('Ignoring invalid CONTRACT_ADDRESS; using BlockchainConfig.contractAddress.');
}

if (!RPC_URL) throw new Error('Missing SEPOLIA_RPC_URL in contracts/.env');
if (!PRIVATE_KEY) throw new Error('Missing ISSUER_PRIVATE_KEY in contracts/.env');
if (!API_KEY || API_KEY.length < 24) {
  throw new Error('RELAYER_API_KEY must be set in contracts/.env and contain at least 24 characters');
}
if (!CONTRACT_ADDRESS || !ethers.isAddress(CONTRACT_ADDRESS)) {
  throw new Error('Missing or invalid CONTRACT_ADDRESS');
}
if (!Number.isInteger(PORT) || PORT < 1 || PORT > 65535) {
  throw new Error('RELAYER_PORT must be a valid TCP port');
}

const ABI = [
  'function certificateIdExists(bytes32) view returns (bool)',
  'function verifyCertificate(bytes32) view returns ((bytes32 certificateId,uint8 certificateType,address recipient,bytes32 achievementHash,uint256 issuedAt,bool revoked) certificate,bool valid)',
  'function issueCertificate(bytes32 certificateId,uint8 certificateType,address recipient,bytes32 achievementHash)',
  'event CertificateIssued(bytes32 indexed certificateId,uint8 indexed certificateType,address indexed recipient,bytes32 achievementHash,uint256 issuedAt)',
];

const provider = new ethers.JsonRpcProvider(RPC_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
const apiKeyBuffer = Buffer.from(API_KEY, 'utf8');
const rateLimitWindowMs = 60_000;
const rateLimitMaxRequests = 10;
const requestWindows = new Map();
const bytes32Pattern = /^0x[0-9a-fA-F]{64}$/;
const zeroBytes32Pattern = /^0x0{64}$/i;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
    'Access-Control-Max-Age': '86400',
  };
}

function sendJson(res, statusCode, value) {
  res.writeHead(statusCode, {
    ...corsHeaders(),
    'Content-Type': 'application/json; charset=utf-8',
  });
  res.end(JSON.stringify(value));
}

function hasValidApiKey(req) {
  const supplied = req.headers['x-api-key'];
  if (typeof supplied !== 'string') return false;
  const suppliedBuffer = Buffer.from(supplied, 'utf8');
  return suppliedBuffer.length === apiKeyBuffer.length &&
    crypto.timingSafeEqual(suppliedBuffer, apiKeyBuffer);
}

function isRateLimited(req) {
  const now = Date.now();
  const client = req.socket.remoteAddress || '127.0.0.1';
  let bucket = requestWindows.get(client);
  if (!bucket || now - bucket.startedAt >= rateLimitWindowMs) {
    bucket = { startedAt: now, count: 0 };
    requestWindows.set(client, bucket);
  }
  bucket.count += 1;
  return bucket.count > rateLimitMaxRequests;
}

async function readJson(req) {
  let body = '';
  for await (const chunk of req) {
    body += chunk;
    if (Buffer.byteLength(body, 'utf8') > 16_384) {
      const error = new Error('Request body too large');
      error.statusCode = 413;
      throw error;
    }
  }
  try {
    return JSON.parse(body);
  } catch (_) {
    const error = new Error('Invalid JSON body');
    error.statusCode = 400;
    throw error;
  }
}

function validateRequest(input) {
  const { certificateId, certificateType, recipientAddress, achievementHash } = input ?? {};
  if (typeof certificateId !== 'string' ||
      !bytes32Pattern.test(certificateId) ||
      zeroBytes32Pattern.test(certificateId)) {
    return 'certificateId must be a non-zero bytes32 hex string';
  }
  if (!Number.isInteger(certificateType) || ![0, 1].includes(certificateType)) {
    return 'certificateType must be 0 or 1';
  }
  if (typeof recipientAddress !== 'string' ||
      !ethers.isAddress(recipientAddress) ||
      recipientAddress === ethers.ZeroAddress) {
    return 'recipientAddress must be a non-zero Ethereum address';
  }
  if (typeof achievementHash !== 'string' ||
      !bytes32Pattern.test(achievementHash) ||
      zeroBytes32Pattern.test(achievementHash)) {
    return 'achievementHash must be a non-zero bytes32 hex string';
  }
  return null;
}

async function findIssueEvent(certificateId) {
  const logs = await contract.queryFilter(
    contract.filters.CertificateIssued(certificateId),
    0,
    'latest',
  );
  return logs[logs.length - 1] ?? null;
}

async function handleIssue(req, res) {
  if (!hasValidApiKey(req)) {
    return sendJson(res, 401, { error: 'Unauthorized' });
  }
  if (isRateLimited(req)) {
    return sendJson(res, 429, { error: 'Rate limit exceeded; maximum 10 requests per minute' });
  }

  let input;
  try {
    input = await readJson(req);
  } catch (error) {
    return sendJson(res, error.statusCode || 400, { error: error.message });
  }

  const validationError = validateRequest(input);
  if (validationError) return sendJson(res, 400, { error: validationError });

  const { certificateId, certificateType, recipientAddress, achievementHash } = input;
  // The public API uses 0/1; the deployed Solidity contract uses 1/2.
  const onChainCertificateType = certificateType + 1;
  try {
    if (await contract.certificateIdExists(certificateId)) {
      const [record] = await contract.verifyCertificate(certificateId);
      const matchesRequest =
        Number(record.certificateType) === onChainCertificateType &&
        record.recipient.toLowerCase() === recipientAddress.toLowerCase() &&
        record.achievementHash.toLowerCase() === achievementHash.toLowerCase();
      if (!matchesRequest) {
        return sendJson(res, 409, { error: 'certificateId already exists with different certificate data' });
      }
      const event = await findIssueEvent(certificateId);
      return sendJson(res, 200, {
        status: 'confirmed',
        transactionHash: event?.transactionHash ?? null,
        blockNumber: event?.blockNumber ?? null,
        issuedAt: new Date(Number(record.issuedAt) * 1000).toISOString(),
      });
    }

    const transaction = await contract.issueCertificate(
      certificateId,
      onChainCertificateType,
      recipientAddress,
      achievementHash,
    );
    const receipt = await transaction.wait(1);
    const issuedEvent = receipt.logs
      .map((log) => {
        try { return contract.interface.parseLog(log); } catch (_) { return null; }
      })
      .find((event) => event?.name === 'CertificateIssued');
    const issuedAt = issuedEvent
      ? new Date(Number(issuedEvent.args.issuedAt) * 1000).toISOString()
      : new Date((await provider.getBlock(receipt.blockNumber)).timestamp * 1000).toISOString();

    return sendJson(res, 200, {
      status: 'confirmed',
      transactionHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      issuedAt,
    });
  } catch (error) {
    console.error('Certificate issuance failed:', error.shortMessage || error.message);
    return sendJson(res, 502, { error: 'Unable to issue certificate on Sepolia' });
  }
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders());
    return res.end();
  }
  if (req.method !== 'POST' || req.url !== '/api/certificates/issue') {
    return sendJson(res, 404, { error: 'Not found' });
  }
  void handleIssue(req, res);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Sepolia certificate relayer listening on 127.0.0.1:${PORT}`);
});
