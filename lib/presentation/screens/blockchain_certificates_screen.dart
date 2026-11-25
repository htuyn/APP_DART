import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/achievement_certificate_model.dart';
import '../providers/blockchain_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/certificate_card.dart';
import '../widgets/certificate_type_badge.dart';
import 'certificate_detail_screen.dart';

class BlockchainCertificatesScreen extends StatefulWidget {
  const BlockchainCertificatesScreen({super.key});

  @override
  State<BlockchainCertificatesScreen> createState() =>
      _BlockchainCertificatesScreenState();
}

class _BlockchainCertificatesScreenState
    extends State<BlockchainCertificatesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  CertificateType? _filter;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final address = context.read<BlockchainProvider>().recipientAddress;
      if (_addressController.text.isEmpty && address != null) {
        _addressController.text = address;
      }
    });
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
    final isVi = language.code == 'vi';
    final certificates = provider.certificates.where(
      (item) => _filter == null || item.type == _filter,
    );
    final eligible = provider.eligibleCertificates.where(
      (item) => _filter == null || item.type == _filter,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(language.t('certificates_title')),
        actions: [
          IconButton(
            tooltip: language.t('sync_blockchain'),
            onPressed: provider.isSyncing ? null : provider.synchronize,
            icon: provider.isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(language.t('certificates_subtitle')),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.t('wallet_title'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(provider.recipientAddress ?? '—', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(language.t(provider.isUsingEmbeddedWallet ? 'wallet_embedded_label' : 'wallet_personal_label'), style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      TextButton.icon(onPressed: () => _showWalletDialog(context, provider, language), icon: const Icon(Icons.swap_horiz), label: Text(language.t('change_wallet'))),
                      if (provider.isUsingEmbeddedWallet)
                        TextButton.icon(onPressed: () => _showExportDialog(context, provider, language), icon: const Icon(Icons.key), label: Text(language.t('backup_wallet_key'))),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          if (provider.noticeMessage != null) ...[
            const SizedBox(height: 8),
            Text(language.t(provider.noticeMessage!), style: Theme.of(context).textTheme.bodySmall),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(provider.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          SegmentedButton<CertificateType?>(
            segments: [
              ButtonSegment(value: null, label: Text(language.t('all_certificates'))),
              ButtonSegment(
                value: CertificateType.achievement,
                label: Text(isVi ? 'Thành tích' : 'Achievement'),
              ),
              ButtonSegment(
                value: CertificateType.courseCompletion,
                label: Text(isVi ? 'Khóa học' : 'Course'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
          ),
          const SizedBox(height: 20),
          Text(language.t('eligible_certificates'),
              style: Theme.of(context).textTheme.titleLarge),
          if (eligible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(language.t('no_certificates')),
            ),
          for (final item in eligible)
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(_certificateName(item.code, language.code)),
                subtitle: CertificateTypeBadge(type: item.type),
                trailing: TextButton(
                  onPressed: provider.recipientAddress == null ||
                          provider.isLoading ||
                          provider.isSyncing
                      ? null
                      : () => provider.requestCertificate(item.code),
                  child: Text(language.t('request_certificate')),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(language.t('certificate_list'),
              style: Theme.of(context).textTheme.titleLarge),
          if (certificates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(language.t('no_certificates')),
            ),
          for (final certificate in certificates)
            CertificateCard(
              certificate: certificate,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CertificateDetailScreen(certificate: certificate),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(language.t('issued_pending_info'),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _showWalletDialog(BuildContext context, BlockchainProvider provider, LanguageProvider language) async {
    _addressController.text = provider.isUsingEmbeddedWallet ? '' : (provider.recipientAddress ?? '');
    final dialogFormKey = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(language.t('change_wallet')),
      content: Form(key: dialogFormKey, child: TextFormField(controller: _addressController, autocorrect: false, enableSuggestions: false, decoration: InputDecoration(labelText: language.t('wallet_address'), hintText: '0x…'), validator: (value) => RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(value?.trim() ?? '') ? null : language.t('wallet_invalid'))),
      actions: [
        TextButton(onPressed: () async { await provider.useEmbeddedWallet(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: Text(language.t('use_embedded_wallet'))),
        FilledButton(onPressed: () async { if (dialogFormKey.currentState?.validate() ?? false) { await provider.setRecipientAddress(_addressController.text); if (dialogContext.mounted) Navigator.pop(dialogContext); } }, child: Text(language.t('save_wallet'))),
      ],
    ));
  }

  Future<void> _showExportDialog(BuildContext context, BlockchainProvider provider, LanguageProvider language) async {
    final key = provider.embeddedPrivateKey ?? '';
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(language.t('backup_wallet_key')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(language.t('wallet_key_warning')), const SizedBox(height: 12), SelectableText('0x$key')]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(language.t('close'))), FilledButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: '0x$key')); if (dialogContext.mounted) Navigator.pop(dialogContext); }, icon: const Icon(Icons.copy), label: Text(language.t('copy_key')))],
    ));
  }

  String _certificateName(String code, String language) => switch (code.trim()) {
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
