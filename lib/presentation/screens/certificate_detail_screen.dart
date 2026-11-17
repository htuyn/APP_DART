import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/blockchain_config.dart';
import '../../data/models/achievement_certificate_model.dart';
import '../providers/blockchain_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/blockchain_status_badge.dart';
import '../widgets/certificate_type_badge.dart';

class CertificateDetailScreen extends StatefulWidget {
  const CertificateDetailScreen({super.key, required this.certificate});

  final AchievementCertificateModel certificate;

  @override
  State<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  bool _verifying = false;
  String? _verificationMessage;
  bool? _isValid;

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _verificationMessage = null;
    });
    try {
      final result = await context.read<BlockchainProvider>()
          .verifyCertificate(widget.certificate.certificateId);
      if (!mounted) return;
      setState(() {
        _isValid = result?.status == CertificateStatus.confirmed;
        final language = context.read<LanguageProvider>();
        _verificationMessage = switch (result?.status) {
          CertificateStatus.confirmed => language.t('on_chain_valid'),
          CertificateStatus.revoked => language.t('on_chain_revoked'),
          CertificateStatus.pending ||
          CertificateStatus.requested ||
          null => language.t('on_chain_not_found'),
          CertificateStatus.failed ||
          CertificateStatus.unverified ||
          CertificateStatus.eligible => language.t('on_chain_unavailable'),
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isValid = false;
        _verificationMessage =
            context.read<LanguageProvider>().t('on_chain_unavailable');
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final certificate = context.watch<BlockchainProvider>().certificates
        .where((item) =>
            item.certificateId.toLowerCase() ==
            widget.certificate.certificateId.toLowerCase())
        .firstOrNull ?? widget.certificate;
    final scheme = Theme.of(context).colorScheme;
    final explorerAvailable = certificate.transactionHash?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(language.t('certificate_detail'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium, size: 52, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    _certificateName(certificate.achievementCode, language.code),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  CertificateTypeBadge(type: certificate.type),
                  const SizedBox(height: 10),
                  BlockchainStatusBadge(status: certificate.status),
                  const Divider(height: 32),
                  _DetailLine(label: language.t('certificate_id'), value: certificate.certificateId),
                  _DetailLine(label: language.t('recipient'), value: certificate.recipientAddress),
                  _DetailLine(
                    label: language.t('issued_at'),
                    value: certificate.issuedAt?.toLocal().toString() ??
                        language.t('not_available'),
                  ),
                  _DetailLine(label: language.t('achievement_hash'), value: certificate.achievementHash),
                  _DetailLine(
                    label: language.t('transaction_hash'),
                    value: certificate.transactionHash ?? language.t('not_available'),
                  ),
                  _DetailLine(
                    label: language.t('block_number'),
                    value: certificate.blockNumber?.toString() ??
                        language.t('not_available'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _verifying ? null : _verify,
            icon: _verifying
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(language.t('verify_on_chain')),
          ),
          if (_verificationMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _verificationMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isValid == true ? scheme.primary : scheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !explorerAvailable
                ? null
                : () => launchUrl(
                      Uri.parse(BlockchainConfig.txExplorerUrl(certificate.transactionHash!)),
                      mode: LaunchMode.externalApplication,
                    ),
            icon: const Icon(Icons.open_in_new),
            label: Text(language.t('view_sepolia_explorer')),
          ),
          if (!explorerAvailable)
            Text(
              language.t('not_available'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _certificateName(String code, String language) => switch (code) {
        'perfectScore' => language == 'vi' ? 'Điểm tuyệt đối' : 'Perfect score',
        'sevenDayStreak' => language == 'vi' ? 'Chuỗi 7 ngày' : '7-day streak',
        'flutterMaster' => 'Flutter Master',
        'knowledgeExplorer' =>
          language == 'vi' ? 'Khám phá kiến thức' : 'Knowledge Explorer',
        'course_completion' =>
          language == 'vi' ? 'Hoàn thành khóa học' : 'Course completion',
        _ => code,
      };
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 3),
            SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
