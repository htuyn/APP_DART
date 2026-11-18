import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../core/constants/blockchain_config.dart';
import '../../domain/blockchain/achievement_verifier.dart';

class IssuedCertificateEvent {
  const IssuedCertificateEvent({
    required this.certificateId,
    required this.transactionHash,
    required this.blockNumber,
  });

  final String certificateId;
  final String? transactionHash;
  final int? blockNumber;
}

class EthereumBlockchainDataSource {
  factory EthereumBlockchainDataSource({
    http.Client? httpClient,
    String rpcUrl = BlockchainConfig.sepoliaRpcUrl,
    String contractAddress = BlockchainConfig.contractAddress,
    String abiAssetPath = BlockchainConfig.abiAssetPath,
    String relayerUrl = BlockchainConfig.issuerRelayerUrl,
  }) {
    final client = httpClient ?? http.Client();
    return EthereumBlockchainDataSource._(
      rpcUrl,
      EthereumAddress.fromHex(contractAddress.replaceFirst(RegExp(r'^0x'), '').toLowerCase()),
      abiAssetPath,
      relayerUrl,
      client,
    );
  }

  EthereumBlockchainDataSource._(
    String rpcUrl,
    this._contractAddress,
    this._abiAssetPath,
    this._relayerUrl,
    this._httpClient,
  ) : _client = Web3Client(rpcUrl, _httpClient);

  final EthereumAddress _contractAddress;
  final String _abiAssetPath;
  final String _relayerUrl;
  final http.Client _httpClient;
  final Web3Client _client;
  Future<DeployedContract>? _contractFuture;

  Future<DeployedContract> _loadContract() => _contractFuture ??= () async {
    final abiJson = await rootBundle.loadString(_abiAssetPath);
    final abi = ContractAbi.fromJson(abiJson, 'AchievementCertificate');
    return DeployedContract(abi, _contractAddress);
  }();

  Future<Map<String, dynamic>?> issueCertificate({
    required String certificateId,
    required int certificateType,
    required String recipientAddress,
    required String achievementHash,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_relayerUrl/api/certificates/issue'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': BlockchainConfig.issuerRelayerApiKey,
      },
      body: jsonEncode({
        'certificateId': certificateId,
        'certificateType': certificateType - 1,
        'recipientAddress': recipientAddress,
        'achievementHash': achievementHash,
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'confirmed') return null;
    return decoded;
  }

  /// Reads the contract's current record. This datasource never signs
  /// transactions and never creates or loads issuer credentials.
  Future<OnChainCertificate?> verifyCertificate(String certificateId) async {
    final contract = await _loadContract();
    final result = await _client.call(
      contract: contract,
      function: contract.function('verifyCertificate'),
      params: [_decodeBytes32(certificateId)],
    );
    final rawRecord = result[0] as List<dynamic>;
    final id = _encodeBytes32(rawRecord[0] as Uint8List);
    if (_isZeroBytes32(id)) return null;

    final issuedAtSeconds = (rawRecord[4] as BigInt).toInt();
    return OnChainCertificate(
      certificateId: id,
      certificateType: (rawRecord[1] as BigInt).toInt(),
      recipientAddress: _addressToHex(rawRecord[2] as EthereumAddress),
      achievementHash: _encodeBytes32(rawRecord[3] as Uint8List),
      issuedAt: DateTime.fromMillisecondsSinceEpoch(
        issuedAtSeconds * 1000,
        isUtc: true,
      ),
      revoked: rawRecord[5] as bool,
      valid: result[1] as bool,
    );
  }

  /// Finds the issue event for one certificate ID in a bounded block window.
  /// A deployment block may be supplied at build time; otherwise the latest
  /// [BlockchainConfig.eventScanWindow] blocks are searched.
  Future<IssuedCertificateEvent?> findCertificateIssuedEvent(
    String certificateId,
  ) async {
    final contract = await _loadContract();
    final event = contract.event('CertificateIssued');
    final latestBlock = await _client.getBlockNumber();
    final configuredStart = BlockchainConfig.contractDeploymentBlock;
    final fromBlock = configuredStart > 0
        ? (configuredStart < latestBlock ? configuredStart : latestBlock)
        : (latestBlock > BlockchainConfig.eventScanWindow
              ? latestBlock - BlockchainConfig.eventScanWindow
              : 0);
    final id = _encodeBytes32(_decodeBytes32(certificateId));
    final logs = await _client.getLogs(
      FilterOptions(
        address: _contractAddress,
        fromBlock: BlockNum.exact(fromBlock),
        toBlock: BlockNum.exact(latestBlock),
        topics: [
          [bytesToHex(event.signature, include0x: true)],
          [id],
        ],
      ),
    );

    for (final log in logs) {
      final decoded = event.decodeResults(
        log.topics ?? const [],
        log.data ?? '0x',
      );
      if (_encodeBytes32(decoded[0] as Uint8List).toLowerCase() !=
          id.toLowerCase()) {
        continue;
      }
      return IssuedCertificateEvent(
        certificateId: id,
        transactionHash: log.transactionHash,
        blockNumber: log.blockNum,
      );
    }
    return null;
  }

  /// Finds certificate IDs from CertificateIssued events for a wallet.
  /// Supply a bounded block range to avoid provider range limits.
  Future<List<String>> findIssuedCertificateIds({
    required String recipientAddress,
    required int fromBlock,
    required int toBlock,
  }) async {
    if (fromBlock < 0 || toBlock < fromBlock) {
      throw ArgumentError('Invalid event block range.');
    }

    final contract = await _loadContract();
    final event = contract.event('CertificateIssued');
    final logs = await _client.getLogs(
      FilterOptions.events(
        contract: contract,
        event: event,
        fromBlock: BlockNum.exact(fromBlock),
        toBlock: BlockNum.exact(toBlock),
      ),
    );
    final recipient = EthereumAddress.fromHex(recipientAddress.replaceFirst(RegExp(r'^0x'), '').toLowerCase());
    final certificateIds = <String>{};

    for (final log in logs) {
      final decoded = event.decodeResults(
        log.topics ?? const [],
        log.data ?? '0x',
      );
      if (_addressToHex(decoded[2] as EthereumAddress).toLowerCase() ==
          _addressToHex(recipient).toLowerCase()) {
        certificateIds.add(_encodeBytes32(decoded[0] as Uint8List));
      }
    }
    return certificateIds.toList(growable: false);
  }

  Future<void> dispose() async {
    await _client.dispose();
    _httpClient.close();
  }

  Uint8List _decodeBytes32(String value) {
    final normalized = value.startsWith('0x') ? value.substring(2) : value;
    if (normalized.length != 64 ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized)) {
      throw FormatException('Expected a 32-byte hex value.', value);
    }
    return Uint8List.fromList(
      List<int>.generate(
        32,
        (index) => int.parse(
          normalized.substring(index * 2, index * 2 + 2),
          radix: 16,
        ),
      ),
    );
  }

  String _addressToHex(EthereumAddress value) =>
      '0x${bytesToHex(value.value, include0x: false)}';

  String _encodeBytes32(Uint8List value) =>
      '0x${bytesToHex(value, include0x: false)}';

  bool _isZeroBytes32(String value) =>
      value.substring(2).split('').every((character) => character == '0');
}
