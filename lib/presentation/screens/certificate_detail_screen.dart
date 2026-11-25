import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/blockchain_config.dart';
import '../../data/models/achievement_certificate_model.dart';
import '../providers/auth_provider.dart';
import '../providers/blockchain_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/digital_certificate_card.dart';

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

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
    final auth = context.watch<AuthProvider?>();
    final user = auth?.currentUser;
    final studentName = user?.name.isNotEmpty == true ? user!.name : user?.email;
    final studentEmail = user?.email;

    final certificate = context.watch<BlockchainProvider>().certificates
        .where((item) =>
            item.certificateId.toLowerCase() ==
            widget.certificate.certificateId.toLowerCase())
        .firstOrNull ?? widget.certificate;
    final scheme = Theme.of(context).colorScheme;
    final explorerAvailable = certificate.transactionHash?.isNotEmpty ?? false;

    final title = _certificateName(certificate.achievementCode, language.code);
    final statusLabel = switch (certificate.status) {
      CertificateStatus.confirmed => language.t('on_chain_verified'),
      CertificateStatus.revoked => language.t('revoked_status'),
      _ => language.t('pending_confirmation'),
    };

    final labels = {
      'academy': language.t('academy'),
      'diploma_heading': language.t('diploma_heading'),
      'recipient': language.t('recipient'),
      'copy_wallet': language.t('copy_wallet'),
      'certificate_id': language.t('certificate_id'),
      'achievement_hash': language.t('achievement_hash'),
      'transaction_hash': language.t('transaction_hash'),
      'copy_transaction': language.t('copy_transaction'),
      'block_number': language.t('block_number'),
      'issued_at': language.t('issued_at'),
      'not_available': language.t('not_available'),
      'sepolia_seal': language.t('sepolia_seal'),
      'certified_student': language.t('certified_student'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(language.t('certificate_detail'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DigitalCertificateCard(
            certificate: certificate,
            title: title,
            statusLabel: statusLabel,
            labels: labels,
            studentName: studentName,
            studentEmail: studentEmail,
            onCopy: (value) {
              final isWallet = value == certificate.recipientAddress;
              final msg = isWallet
                  ? language.t('copied_wallet')
                  : language.t('copied_transaction');
              _copyToClipboard(value, msg);
            },
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
          if (!explorerAvailable) ...[
            const SizedBox(height: 4),
            Text(
              language.t('not_available'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
