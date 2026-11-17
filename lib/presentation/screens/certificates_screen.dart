import 'package:material_ui/material_ui.dart';
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
        title: Text(isVietnamese ? 'ChÃ¡Â»Â©ng chÃ¡Â»â€° blockchain' : 'Blockchain certificates'),
        actions: [
          IconButton(
            tooltip: isVietnamese ? 'Ã„ÂÃ¡Â»â€œng bÃ¡Â»â„¢' : 'Sync',
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
              labelText: isVietnamese ? 'Ã„ÂÃ¡Â»â€¹a chÃ¡Â»â€° vÃƒÂ­ Ethereum' : 'Ethereum wallet address',
              hintText: '0xÃ¢â‚¬Â¦',
              suffixIcon: IconButton(
                tooltip: isVietnamese ? 'LÃ†Â°u Ã„â€˜Ã¡Â»â€¹a chÃ¡Â»â€° vÃƒÂ­' : 'Save wallet address',
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
            isVietnamese ? 'Ã„ÂÃ¡Â»Â§ Ã„â€˜iÃ¡Â»Âu kiÃ¡Â»â€¡n nhÃ¡ÂºÂ­n' : 'Eligible to request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.eligibleCertificates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isVietnamese
                    ? 'ChÃ†Â°a cÃƒÂ³ chÃ¡Â»Â©ng chÃ¡Â»â€° nÃƒÂ o Ã„â€˜Ã¡Â»Â§ Ã„â€˜iÃ¡Â»Âu kiÃ¡Â»â€¡n.'
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
                      ? (isVietnamese ? 'ThÃƒÂ nh tÃƒÂ­ch' : 'Achievement')
                      : (isVietnamese ? 'HoÃƒÂ n thÃƒÂ nh khÃƒÂ³a hÃ¡Â»Âc' : 'Course completion'),
                ),
                trailing: TextButton(
                  onPressed: provider.recipientAddress == null
                      ? null
                      : () => provider.requestCertificate(eligibility.code),
                  child: Text(isVietnamese ? 'YÃƒÂªu cÃ¡ÂºÂ§u' : 'Request'),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            isVietnamese ? 'ChÃ¡Â»Â©ng chÃ¡Â»â€° Ã„â€˜ÃƒÂ£ yÃƒÂªu cÃ¡ÂºÂ§u' : 'Requested certificates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.certificates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isVietnamese ? 'ChÃ†Â°a cÃƒÂ³ yÃƒÂªu cÃ¡ÂºÂ§u.' : 'No requests yet.',
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
                  tooltip: isVietnamese ? 'XÃƒÂ¡c minh' : 'Verify',
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
    'perfectScore' => vi ? 'Ã„ÂiÃ¡Â»Æ’m tuyÃ¡Â»â€¡t Ã„â€˜Ã¡Â»â€˜i' : 'Perfect score',
    'sevenDayStreak' => vi ? 'ChuÃ¡Â»â€”i 7 ngÃƒÂ y' : '7-day streak',
    'flutterMaster' => vi ? 'Flutter Master' : 'Flutter Master',
    'knowledgeExplorer' => vi ? 'KhÃƒÂ¡m phÃƒÂ¡ kiÃ¡ÂºÂ¿n thÃ¡Â»Â©c' : 'Knowledge Explorer',
    'course_completion' => vi ? 'HoÃƒÂ n thÃƒÂ nh khÃƒÂ³a hÃ¡Â»Âc' : 'Course completion',
    _ => code,
  };

  String _statusLabel(CertificateStatus status, bool vi) => switch (status) {
    CertificateStatus.eligible => vi ? 'Ã„ÂÃ¡Â»Â§ Ã„â€˜iÃ¡Â»Âu kiÃ¡Â»â€¡n' : 'Eligible',
    CertificateStatus.requested => vi ? 'Ã„ÂÃƒÂ£ gÃ¡Â»Â­i yÃƒÂªu cÃ¡ÂºÂ§u' : 'Requested',
    CertificateStatus.pending => vi ? 'Ã„Âang chÃ¡Â»Â xÃƒÂ¡c minh/cÃ¡ÂºÂ¥p phÃƒÂ¡t' : 'Pending issuer/chain confirmation',
    CertificateStatus.confirmed => vi ? 'Ã„ÂÃƒÂ£ xÃƒÂ¡c nhÃ¡ÂºÂ­n trÃƒÂªn Sepolia' : 'Confirmed on Sepolia',
    CertificateStatus.failed => vi ? 'XÃƒÂ¡c minh thÃ¡ÂºÂ¥t bÃ¡ÂºÂ¡i' : 'Verification failed',
    CertificateStatus.revoked => vi ? 'Ã„ÂÃƒÂ£ thu hÃ¡Â»â€œi' : 'Revoked',
    CertificateStatus.unverified => vi ? 'ChÃ†Â°a xÃƒÂ¡c minh' : 'Unverified',
  };

  IconData _statusIcon(CertificateStatus status) => switch (status) {
    CertificateStatus.confirmed => Icons.verified,
    CertificateStatus.revoked => Icons.block,
    CertificateStatus.failed || CertificateStatus.unverified => Icons.error_outline,
    _ => Icons.hourglass_top,
  };
}
