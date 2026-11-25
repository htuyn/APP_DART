import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/core/constants/blockchain_config.dart';
import 'package:flutter_quiz_bilingual/data/datasources/ethereum_blockchain_datasource.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

const _testContractAddress = '0x1111111111111111111111111111111111111111';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('posts issuance with API key and API certificate type mapping', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(jsonEncode({
        'status': 'confirmed',
        'transactionHash': '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'blockNumber': 123,
        'issuedAt': DateTime.utc(2026).toIso8601String(),
      }), 200);
    });
    final datasource = EthereumBlockchainDataSource(
      httpClient: client,
      relayerUrl: 'http://127.0.0.1:8787',
      contractAddress: _testContractAddress,
    );

    final result = await datasource.issueCertificate(
      certificateId: '0x${List.filled(64, '1').join()}',
      certificateType: 1,
      recipientAddress: '0x1111111111111111111111111111111111111111',
      achievementHash: '0x${List.filled(64, '2').join()}',
    );

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(capturedRequest.headers['X-API-Key'], BlockchainConfig.issuerRelayerApiKey);
    expect(body['certificateType'], 0);
    expect(result?['status'], 'confirmed');
    expect(result?['blockNumber'], 123);
    await datasource.dispose();
  });

  test('filters CertificateIssued by indexed certificate ID in the configured window', () async {
    final abiJson = await rootBundle.loadString(BlockchainConfig.abiAssetPath);
    final contract = DeployedContract(
      ContractAbi.fromJson(abiJson, 'AchievementCertificate'),
      EthereumAddress.fromHex(_testContractAddress),
    );
    final issueEvent = contract.event('CertificateIssued');
    const certificateId =
        '0x1111111111111111111111111111111111111111111111111111111111111111';
    const achievementHash =
        '2222222222222222222222222222222222222222222222222222222222222222';
    const transactionHash =
        '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const recipient = '0x1111111111111111111111111111111111111111';
    const contractAddress = _testContractAddress;

    Map<String, dynamic>? eventFilter;
    final client = MockClient((request) async {
      final rpcRequest = jsonDecode(request.body) as Map<String, dynamic>;
      if (rpcRequest['method'] == 'eth_blockNumber') {
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': rpcRequest['id'], 'result': '0x10000'}),
          200,
        );
      }
      if (rpcRequest['method'] == 'eth_getLogs') {
        eventFilter = (rpcRequest['params'] as List).single as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': rpcRequest['id'],
            'result': [
              {
                'removed': false,
                'logIndex': '0x0',
                'transactionIndex': '0x1',
                'transactionHash': transactionHash,
                'blockHash': '0x${List.filled(64, 'b').join()}',
                'blockNumber': '0x10000',
                'address': contractAddress,
                'data': '0x$achievementHash${BigInt.from(1700000000).toRadixString(16).padLeft(64, '0')}',
                'topics': [
                  '0x${bytesToHex(issueEvent.signature, include0x: false)}',
                  certificateId,
                  '0x${BigInt.one.toRadixString(16).padLeft(64, '0')}',
                  '0x${recipient.substring(2).padLeft(64, '0')}',
                ],
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': rpcRequest['id'], 'result': null}),
        200,
      );
    });
    final datasource = EthereumBlockchainDataSource(httpClient: client, contractAddress: _testContractAddress);

    final result = await datasource.findCertificateIssuedEvent(certificateId);

    expect(result?.certificateId, certificateId);
    expect(result?.transactionHash, transactionHash);
    expect(result?.blockNumber, 65536);
    expect(eventFilter?['address'], contractAddress);
    expect(eventFilter?['fromBlock'], '0xec78');
    expect(eventFilter?['toBlock'], '0x10000');
    expect((eventFilter?['topics'] as List)[1], [certificateId]);

    await datasource.dispose();
  });
}
