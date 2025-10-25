import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/theme_controller.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../contacts/application/contacts_controller.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Family contacts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
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
          const Divider(height: 32),

          Text('Preferred family member', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Builder(builder: (context) {
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
          const SizedBox(height: 8),

          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
          const Divider(height: 32),

          Text('Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Share location in help requests'),
            value: locationEnabled,
            onChanged: (v) => ref.read(locationEnabledProvider.notifier).setEnabled(v),
          ),
          const Divider(height: 32),

          Text('Reminder timer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
