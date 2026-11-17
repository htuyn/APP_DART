import 'package:material_ui/material_ui.dart';
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
                    Text(language.t('wallet_guidance'),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: language.t('wallet_address'),
                        hintText: '0x0000…',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final address = value?.trim() ?? '';
                        return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address)
                            ? null
                            : language.t('wallet_invalid');
                      },
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          await provider.setRecipientAddress(
                            _addressController.text,
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(language.t('save_wallet')),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  onPressed: provider.recipientAddress == null
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
