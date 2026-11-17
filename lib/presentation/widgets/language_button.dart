import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.language_rounded, size: 18),
        label: Text(
          lang.isVietnamese ? 'VI' : 'EN',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        tooltip: lang.t('language'),
        onPressed: lang.toggleLanguage,
      ),
    );
  }
}
