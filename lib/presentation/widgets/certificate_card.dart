import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/achievement_certificate_model.dart';
import '../providers/language_provider.dart';
import 'blockchain_status_badge.dart';
import 'certificate_type_badge.dart';

class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.certificate,
    this.onTap,
  });

  final AchievementCertificateModel certificate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _certificateName(certificate.achievementCode, language.code),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CertificateTypeBadge(type: certificate.type),
                  BlockchainStatusBadge(status: certificate.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${language.t('recipient')}: ${_shortAddress(certificate.recipientAddress)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortAddress(String address) =>
      address.length > 14 ? '${address.substring(0, 8)}…${address.substring(address.length - 6)}' : address;

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
