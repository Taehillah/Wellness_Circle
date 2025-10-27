import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../../shared/theme/theme_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../contacts/application/contacts_controller.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  static const Color _panelColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locationEnabled = ref.watch(locationEnabledProvider);
    final timerHours = ref.watch(timerHoursProvider);
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;

    final scaffoldColor = isDark ? const Color(0xFF0B1220) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final fillColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    final settingsTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFF2563EB),
        onPrimary: Colors.white,
        surface: scaffoldColor,
        onSurface: onSurface,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: fillColor,
        labelStyle: baseTheme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        prefixIconColor: isDark ? Colors.white70 : Colors.black45,
        suffixIconColor: isDark ? Colors.white54 : Colors.black38,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
      ),
      radioTheme: baseTheme.radioTheme.copyWith(
        fillColor: WidgetStateProperty.all(const Color(0xFF2563EB)),
      ),
      switchTheme: baseTheme.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.grey.shade300),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF2563EB).withOpacity(isDark ? 0.7 : 0.6)
              : (isDark ? Colors.white24 : Colors.black12),
        ),
      ),
      sliderTheme: baseTheme.sliderTheme.copyWith(
        activeTrackColor: const Color(0xFF2563EB),
        inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
        thumbColor: const Color(0xFF2563EB),
      ),
      listTileTheme: baseTheme.listTileTheme.copyWith(
        iconColor: onSurface,
        textColor: onSurface,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
      ),
    );

    final sectionSpacing = 20.0;
    final sectionTitleColor = isDark ? Colors.white : Colors.black87;
    final sectionIconColor = Colors.white;
    final sectionIconBackground = Colors.white.withOpacity(isDark ? 0.18 : 0.25);

    return Theme(
      data: settingsTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Settings'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.group_add_outlined,
                title: 'Family contacts',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(contactsControllerProvider.notifier)
                              .addContact(_nameController.text, _phoneController.text);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact added')),
                          );
                          _nameController.clear();
                          _phoneController.clear();
                        },
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.star_border_rounded,
                title: 'Preferred family member',
                child: Builder(
                  builder: (context) {
                    final contacts = ref.watch(contactsControllerProvider).contacts;
                    final preferredId = ref.watch(preferredContactProvider);
                    if (contacts.isEmpty) {
                      return const Text('No contacts yet. Add one above.');
                    }
                    final items = contacts
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text('${c.name} (${c.phone})'),
                          ),
                        )
                        .toList();
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: preferredId != null && contacts.any((c) => c.id == preferredId)
                                ? preferredId
                                : null,
                            items: items,
                            onChanged: (id) =>
                                ref.read(preferredContactProvider.notifier).setPreferred(id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: preferredId == null
                              ? null
                              : () =>
                                  ref.read(preferredContactProvider.notifier).setPreferred(null),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.brightness_medium_outlined,
                title: 'Appearance',
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Use system setting'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m!),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.location_on_outlined,
                title: 'Location',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share location in help requests'),
                  value: locationEnabled,
                  onChanged: (v) => ref.read(locationEnabledProvider.notifier).setEnabled(v),
                ),
              ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.timer_outlined,
                title: 'Reminder timer',
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 24,
                        divisions: 23,
                        label: '$timerHours h',
                        value: timerHours.toDouble(),
                        onChanged: (v) => ref.read(timerHoursProvider.notifier).setHours(v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '$timerHours h',
                        textAlign: TextAlign.right,
                        style: settingsTheme.textTheme.bodyMedium,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
                backgroundColor: _panelColor,
                titleColor: sectionTitleColor,
                iconColor: sectionIconColor,
                iconBackgroundColor: sectionIconBackground,
                icon: Icons.person_outline,
                title: 'Account',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                      if (!mounted) return;
                      context.go(AppRoute.login.path);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
                ),
              ),
              SizedBox(height: sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    required this.backgroundColor,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color backgroundColor;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: backgroundColor,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
