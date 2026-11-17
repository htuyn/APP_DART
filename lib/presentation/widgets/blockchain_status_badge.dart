import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/achievement_certificate_model.dart';
import '../providers/language_provider.dart';

class BlockchainStatusBadge extends StatelessWidget {
  const BlockchainStatusBadge({super.key, required this.status});

  final CertificateStatus status;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final (labelKey, color) = switch (status) {
      CertificateStatus.eligible => ('status_eligible', Colors.blue),
      CertificateStatus.pending || CertificateStatus.requested =>
        ('status_pending', Colors.orange),
      CertificateStatus.confirmed => ('status_confirmed', Colors.green),
      CertificateStatus.failed || CertificateStatus.unverified =>
        ('status_failed', Theme.of(context).colorScheme.error),
      CertificateStatus.revoked => ('status_revoked', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        language.t(labelKey),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
