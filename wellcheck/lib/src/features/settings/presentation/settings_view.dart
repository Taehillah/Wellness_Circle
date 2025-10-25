import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/theme_controller.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../contacts/application/contacts_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../../shared/router/app_router.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  static const List<Color> _gradient = [
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF38BDF8),
  ];

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
    final textTheme = baseTheme.textTheme;
    final colorScheme = baseTheme.colorScheme;

    final settingsTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFF2563EB),
        onPrimary: Colors.white,
        surface: const Color(0xFF0B1220),
        onSurface: Colors.white,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        labelStyle: baseTheme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white54,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
        ),
      ),
      radioTheme: baseTheme.radioTheme.copyWith(
        fillColor: MaterialStateProperty.resolveWith((states) => Colors.white),
      ),
      switchTheme: baseTheme.switchTheme.copyWith(
        thumbColor: MaterialStateProperty.resolveWith((states) => Colors.white),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? const Color(0xFF2563EB).withOpacity(0.7)
              : Colors.white24,
        ),
      ),
      sliderTheme: baseTheme.sliderTheme.copyWith(
        activeTrackColor: const Color(0xFF38BDF8),
        inactiveTrackColor: Colors.white24,
        thumbColor: const Color(0xFF2563EB),
      ),
      listTileTheme: baseTheme.listTileTheme.copyWith(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),
    );

    final sectionSpacing = 20.0;

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
            children: [
              _SettingsSection(
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
              icon: Icons.star_border_rounded,
              title: 'Preferred family member',
              child: Builder(builder: (context) {
            final contacts = ref.watch(contactsControllerProvider).contacts;
            final preferredId = ref.watch(preferredContactProvider);
            if (contacts.isEmpty) {
              return const Text('No contacts yet. Add one above.');
            }
            final items = contacts
                .map((c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text('${c.name} (${c.phone})'),
                    ))
                .toList();
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: preferredId != null && contacts.any((c) => c.id == preferredId)
                        ? preferredId
                        : null,
                    items: items,
                    decoration: const InputDecoration(
                      labelText: 'Preferred contact',
                      prefixIcon: Icon(Icons.star_outline),
                    ),
                    onChanged: (id) => ref.read(preferredContactProvider.notifier).setPreferred(id),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: preferredId == null
                      ? null
                      : () => ref.read(preferredContactProvider.notifier).setPreferred(null),
                ),
              ],
            );
          }),
            ),
              SizedBox(height: sectionSpacing),
              _SettingsSection(
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
              icon: Icons.timer_outlined,
              title: 'Reminder timer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
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
                  style: textTheme.bodyMedium,
                ),
              )
            ],
          ),
                ],
              ),
            ),
              SizedBox(height: sectionSpacing),
            _SettingsSection(
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
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
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
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: _SettingsViewState._gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
