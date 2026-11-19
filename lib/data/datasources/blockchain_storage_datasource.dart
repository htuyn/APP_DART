import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../models/achievement_certificate_model.dart';
import 'auth_storage_datasource.dart';

class BlockchainStorageDataSource {
  static const String _certificatesKey = 'blockchain_certificates_v1';
  static const String _recipientAddressKey = 'blockchain_recipient_address_v1';
  static const String _embeddedAddressKey = 'embedded_wallet_address';
  static const String _embeddedPrivateKeyKey = 'embedded_wallet_private_key';

  Future<String> _getScopedKey(String baseKey) async {
    final user = await AuthStorageDataSource().getCurrentUser();
    if (user != null && user.id.isNotEmpty) {
      return '${baseKey}_${user.id}';
    }
    return baseKey;
  }

  Future<List<AchievementCertificateModel>> loadCertificates() async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_certificatesKey);
    final records = preferences.getStringList(key) ?? const [];
    return records.map((record) => AchievementCertificateModel.fromJson(
      jsonDecode(record) as Map<String, dynamic>,
    )).toList(growable: false);
  }

  Future<void> saveCertificate(AchievementCertificateModel certificate) async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_certificatesKey);
    final records = preferences.getStringList(key) ?? <String>[];
    final encoded = jsonEncode(certificate.toJson());
    final index = records.indexWhere((record) {
      final decoded = jsonDecode(record) as Map<String, dynamic>;
      return (decoded['certificate_id'] as String).toLowerCase() == certificate.certificateId.toLowerCase();
    });
    if (index < 0) { records.add(encoded); } else { records[index] = encoded; }
    await preferences.setStringList(key, records);
  }

  Future<String> ensureEmbeddedWallet() async {
    final preferences = await SharedPreferences.getInstance();
    final addressKey = await _getScopedKey(_embeddedAddressKey);
    final privateKeyKey = await _getScopedKey(_embeddedPrivateKeyKey);
    final recipientKey = await _getScopedKey(_recipientAddressKey);

    var address = preferences.getString(addressKey);
    var privateKey = preferences.getString(privateKeyKey);
    if (address == null || privateKey == null) {
      final wallet = EthPrivateKey.createRandom(Random.secure());
      final generatedAddress = '0x${bytesToHex(wallet.address.value, include0x: false)}';
      final generatedPrivateKey = wallet.privateKeyInt.toRadixString(16).padLeft(64, '0');
      await preferences.setString(addressKey, generatedAddress);
      await preferences.setString(privateKeyKey, generatedPrivateKey);
      address = generatedAddress;
    }
    if (preferences.getString(recipientKey) == null) {
      await preferences.setString(recipientKey, address);
    }
    return address;
  }

  Future<String?> loadEmbeddedPrivateKey() async {
    await ensureEmbeddedWallet();
    final privateKeyKey = await _getScopedKey(_embeddedPrivateKeyKey);
    return (await SharedPreferences.getInstance()).getString(privateKeyKey);
  }

  Future<String?> loadEmbeddedAddress() async {
    await ensureEmbeddedWallet();
    final addressKey = await _getScopedKey(_embeddedAddressKey);
    return (await SharedPreferences.getInstance()).getString(addressKey);
  }

  Future<void> useEmbeddedWallet() async {
    final address = await ensureEmbeddedWallet();
    await saveRecipientAddress(address);
  }

  Future<void> saveRecipientAddress(String address) async {
    final preferences = await SharedPreferences.getInstance();
    final recipientKey = await _getScopedKey(_recipientAddressKey);
    await preferences.setString(recipientKey, address.trim());
  }

  Future<String?> loadRecipientAddress() async {
    await ensureEmbeddedWallet();
    final preferences = await SharedPreferences.getInstance();
    final recipientKey = await _getScopedKey(_recipientAddressKey);
    return preferences.getString(recipientKey);
  }
}
