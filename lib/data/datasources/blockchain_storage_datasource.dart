import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_certificate_model.dart';

class BlockchainStorageDataSource {
  static const String _certificatesKey = 'blockchain_certificates_v1';
  static const String _recipientAddressKey = 'blockchain_recipient_address_v1';

  Future<List<AchievementCertificateModel>> loadCertificates() async {
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_certificatesKey) ?? const [];
    return records
        .map(
          (record) => AchievementCertificateModel.fromJson(
            jsonDecode(record) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveCertificate(AchievementCertificateModel certificate) async {
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_certificatesKey) ?? <String>[];
    final encoded = jsonEncode(certificate.toJson());
    final index = records.indexWhere((record) {
      final decoded = jsonDecode(record) as Map<String, dynamic>;
      return (decoded['certificate_id'] as String).toLowerCase() ==
          certificate.certificateId.toLowerCase();
    });
    if (index < 0) {
      records.add(encoded);
    } else {
      records[index] = encoded;
    }
    await preferences.setStringList(_certificatesKey, records);
  }

  Future<void> saveRecipientAddress(String address) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_recipientAddressKey, address.trim());
  }

  Future<String?> loadRecipientAddress() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_recipientAddressKey);
  }
}
