import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../models/achievement_certificate_model.dart';

class BlockchainStorageDataSource {
  static const String _certificatesKey = 'blockchain_certificates_v1';
  static const String _recipientAddressKey = 'blockchain_recipient_address_v1';
  static const String _embeddedAddressKey = 'embedded_wallet_address';
  static const String _embeddedPrivateKeyKey = 'embedded_wallet_private_key';

  Future<List<AchievementCertificateModel>> loadCertificates() async {
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_certificatesKey) ?? const [];
    return records.map((record) => AchievementCertificateModel.fromJson(
      jsonDecode(record) as Map<String, dynamic>,
    )).toList(growable: false);
  }

  Future<void> saveCertificate(AchievementCertificateModel certificate) async {
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_certificatesKey) ?? <String>[];
    final encoded = jsonEncode(certificate.toJson());
    final index = records.indexWhere((record) {
      final decoded = jsonDecode(record) as Map<String, dynamic>;
      return (decoded['certificate_id'] as String).toLowerCase() == certificate.certificateId.toLowerCase();
    });
    if (index < 0) { records.add(encoded); } else { records[index] = encoded; }
    await preferences.setStringList(_certificatesKey, records);
  }

  Future<String> ensureEmbeddedWallet() async {
    final preferences = await SharedPreferences.getInstance();
    var address = preferences.getString(_embeddedAddressKey);
    var privateKey = preferences.getString(_embeddedPrivateKeyKey);
    if (address == null || privateKey == null) {
      final wallet = EthPrivateKey.createRandom(Random.secure());
      final generatedAddress = '0x${bytesToHex(wallet.address.value, include0x: false)}';
      final generatedPrivateKey = wallet.privateKeyInt.toRadixString(16).padLeft(64, '0');
      await preferences.setString(_embeddedAddressKey, generatedAddress);
      await preferences.setString(_embeddedPrivateKeyKey, generatedPrivateKey);
      address = generatedAddress;
    }
    if (preferences.getString(_recipientAddressKey) == null) {
      await preferences.setString(_recipientAddressKey, address);
    }
    return address;
  }

  Future<String?> loadEmbeddedPrivateKey() async {
    await ensureEmbeddedWallet();
    return (await SharedPreferences.getInstance()).getString(_embeddedPrivateKeyKey);
  }

  Future<String?> loadEmbeddedAddress() async {
    await ensureEmbeddedWallet();
    return (await SharedPreferences.getInstance()).getString(_embeddedAddressKey);
  }

  Future<void> useEmbeddedWallet() async {
    final address = await ensureEmbeddedWallet();
    await saveRecipientAddress(address);
  }

  Future<void> saveRecipientAddress(String address) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_recipientAddressKey, address.trim());
  }

  Future<String?> loadRecipientAddress() async {
    await ensureEmbeddedWallet();
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_recipientAddressKey);
  }
}
