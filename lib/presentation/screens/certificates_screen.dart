import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/achievement_certificate_model.dart';
import '../providers/blockchain_provider.dart';
import '../providers/language_provider.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlockchainProvider>();
    final language = context.watch<LanguageProvider>();
    final isVietnamese = language.code == 'vi';
    if (_addressController.text.isEmpty && provider.recipientAddress != null) {
      _addressController.text = provider.recipientAddress!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isVietnamese ? 'Chứng chỉ blockchain' : 'Blockchain certificates'),
        actions: [
          IconButton(
            tooltip: isVietnamese ? 'Đồng bộ' : 'Sync',
            onPressed: provider.isSyncing
                ? null
                : () => provider.synchronize(),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _addressController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: isVietnamese ? 'Địa chỉ ví Ethereum' : 'Ethereum wallet address',
              hintText: '0x…',
              suffixIcon: IconButton(
                tooltip: isVietnamese ? 'Lưu địa chỉ ví' : 'Save wallet address',
                onPressed: () => provider.setRecipientAddress(
                  _addressController.text,
                ),
                icon: const Icon(Icons.save_outlined),
              ),
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            isVietnamese ? 'Đủ điều kiện nhận' : 'Eligible to request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.eligibleCertificates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isVietnamese
                    ? 'Chưa có chứng chỉ nào đủ điều kiện.'
                    : 'No certificates are eligible yet.',
              ),
            ),
          for (final eligibility in provider.eligibleCertificates)
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(_certificateName(eligibility.code, isVietnamese)),
                subtitle: Text(
                  eligibility.type == CertificateType.achievement
                      ? (isVietnamese ? 'Thành tích' : 'Achievement')
                      : (isVietnamese ? 'Hoàn thành khóa học' : 'Course completion'),
                ),
                trailing: TextButton(
                  onPressed: provider.recipientAddress == null
                      ? null
                      : () => provider.requestCertificate(eligibility.code),
                  child: Text(isVietnamese ? 'Yêu cầu' : 'Request'),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            isVietnamese ? 'Chứng chỉ đã yêu cầu' : 'Requested certificates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.certificates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isVietnamese ? 'Chưa có yêu cầu.' : 'No requests yet.',
              ),
            ),
          for (final certificate in provider.certificates)
            Card(
              child: ListTile(
                leading: Icon(_statusIcon(certificate.status)),
                title: Text(
                  _certificateName(certificate.achievementCode, isVietnamese),
                ),
                subtitle: Text(
                  '${_statusLabel(certificate.status, isVietnamese)}\n'
                  '${certificate.certificateId}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: isVietnamese ? 'Xác minh' : 'Verify',
                  onPressed: () => provider.synchronize(),
                  icon: const Icon(Icons.verified_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _certificateName(String code, bool vi) => switch (code) {
    'perfectScore' => vi ? 'Điểm tuyệt đối' : 'Perfect score',
    'sevenDayStreak' => vi ? 'Chuỗi 7 ngày' : '7-day streak',
    'flutterMaster' => vi ? 'Flutter Master' : 'Flutter Master',
    'knowledgeExplorer' => vi ? 'Khám phá kiến thức' : 'Knowledge Explorer',
    'course_completion' => vi ? 'Hoàn thành khóa học' : 'Course completion',
    _ => code,
  };

  String _statusLabel(CertificateStatus status, bool vi) => switch (status) {
    CertificateStatus.eligible => vi ? 'Đủ điều kiện' : 'Eligible',
    CertificateStatus.requested => vi ? 'Đã gửi yêu cầu' : 'Requested',
    CertificateStatus.pending => vi ? 'Đang chờ xác minh/cấp phát' : 'Pending issuer/chain confirmation',
    CertificateStatus.confirmed => vi ? 'Đã xác nhận trên Sepolia' : 'Confirmed on Sepolia',
    CertificateStatus.failed => vi ? 'Xác minh thất bại' : 'Verification failed',
    CertificateStatus.revoked => vi ? 'Đã thu hồi' : 'Revoked',
    CertificateStatus.unverified => vi ? 'Chưa xác minh' : 'Unverified',
  };

  IconData _statusIcon(CertificateStatus status) => switch (status) {
    CertificateStatus.confirmed => Icons.verified,
    CertificateStatus.revoked => Icons.block,
    CertificateStatus.failed || CertificateStatus.unverified => Icons.error_outline,
    _ => Icons.hourglass_top,
  };
}
