import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/achievement_certificate_model.dart';
import '../providers/language_provider.dart';

class CertificateTypeBadge extends StatelessWidget {
  const CertificateTypeBadge({super.key, required this.type});

  final CertificateType type;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final label = type == CertificateType.achievement
        ? language.t('achievement_certificate')
        : language.t('course_certificate');
    final scheme = Theme.of(context).colorScheme;
    final color = type == CertificateType.achievement
        ? scheme.tertiary
        : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
