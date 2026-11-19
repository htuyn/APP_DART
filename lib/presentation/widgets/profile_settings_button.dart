import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_page_route.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

class ProfileSettingsButton extends StatelessWidget {
  const ProfileSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: lang.translate(
        vi: 'Cá nhân & Cài đặt',
        en: 'Profile & Settings',
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: scheme.onSurface,
            size: 26,
          ),
          onPressed: () => showProfileSettingsSheet(context),
        ),
      ),
    );
  }
}

void showProfileSettingsSheet(BuildContext context) {
  // Lấy sẵn provider từ context gốc để truyền vào route riêng của modal
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final langProvider = Provider.of<LanguageProvider>(context, listen: false);
  AuthProvider? authProvider;
  try {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  } catch (_) {
    // Graceful fallback nếu AuthProvider chưa khởi tạo trong test
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent, // Để màu nền do Container bên trong tự quản lý theo theme động
    builder: (sheetContext) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: langProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          if (authProvider != null)
            ChangeNotifierProvider.value(value: authProvider!),
        ],
        child: Builder(
          builder: (nestedContext) {
            final theme = nestedContext.watch<ThemeProvider>();
            // Xác định trạng thái sáng/tối dựa trên mode hiện tại của ThemeProvider
            final isDark = theme.mode == ThemeMode.dark ||
                (theme.mode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(nestedContext) == Brightness.dark);

            // Tạo scheme màu động cho modal
            final sheetScheme = ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            );

            return Theme(
              data: ThemeData(
                useMaterial3: true,
                brightness: isDark ? Brightness.dark : Brightness.light,
                colorScheme: sheetScheme,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const SafeArea(
                  child: SingleChildScrollView(
                    child: _ProfileSettingsSheetContent(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class _ProfileSettingsSheetContent extends StatelessWidget {
  const _ProfileSettingsSheetContent();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = context.watch<ThemeProvider>();
    AuthProvider? auth;
    try {
      auth = context.watch<AuthProvider>();
    } catch (_) {}

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = scheme.onSurface;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final headerColor = scheme.onSurface;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final user = auth?.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Learner / User Profile Info Block
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isAuthenticated
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuthenticated ? user!.name : lang.t('guest_user'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAuthenticated ? user!.email : lang.t('learner'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Auth Action Buttons
          if (isAuthenticated) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(lang.t('logout_confirm')),
                    content: Text(lang.t('logout_body')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(lang.t('close')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: scheme.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(lang.t('logout')),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await auth?.logout();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: Icon(Icons.logout_rounded, color: scheme.error, size: 18),
              label: Text(
                lang.t('logout'),
                style: TextStyle(
                    color: scheme.error, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(openAppPage(const LoginScreen()));
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(lang.t('login')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(openAppPage(const RegisterScreen()));
                    },
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(lang.t('register')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 18),

          // 2. Language Switch Section
          Row(
            children: [
              Icon(Icons.language_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                lang.t('language'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  label: 'Tiếng Việt',
                  icon: Icons.flag_rounded,
                  selected: lang.isVietnamese,
                  onTap: () => lang.setLanguage(AppLanguage.vi),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionTile(
                  label: 'English',
                  icon: Icons.language_outlined,
                  selected: !lang.isVietnamese,
                  onTap: () => lang.setLanguage(AppLanguage.en),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Theme Mode Switch Section
          Row(
            children: [
              Icon(Icons.contrast_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                lang.t('appearance'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  label: lang.t('theme_system'),
                  icon: Icons.brightness_auto_rounded,
                  selected: theme.mode == ThemeMode.system,
                  onTap: () => theme.setMode(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OptionTile(
                  label: lang.t('theme_light'),
                  icon: Icons.light_mode_rounded,
                  selected: theme.mode == ThemeMode.light,
                  onTap: () => theme.setMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OptionTile(
                  label: lang.t('theme_dark'),
                  icon: Icons.dark_mode_rounded,
                  selected: theme.mode == ThemeMode.dark,
                  onTap: () => theme.setMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = selected
        ? scheme.primaryContainer
        : (isDark ? scheme.surfaceContainerHighest : scheme.surface);
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final border = selected ? scheme.primary : scheme.outlineVariant;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: border,
          width: selected ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}