import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../auth/application/auth_controller.dart';
import '../application/contacts_controller.dart';

class ContactsView extends ConsumerWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsControllerProvider);
    final controller = ref.read(contactsControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddContact(context),
        icon: const Icon(Icons.add),
        label: const Text('Add contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'These contacts will be notified when you request help.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: state.contacts.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 60),
                          Center(
                            child: Text('No contacts yet. Tap “Add contact” to get started.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: state.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = state.contacts[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  LucideIcons.phone,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(contact.name),
                              subtitle: Text(
                                '${contact.phone}\nAdded ${DateFormatting.relative(contact.createdAt)}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: state.status == ContactsStatus.loading
                                    ? null
                                    : () => controller.removeContact(contact.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (user?.isAdmin == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Admins can manage org-wide contacts from the dashboard.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openAddContact(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddContactSheet(),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet();

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = ref.read(contactsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await controller.addContact(
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );
    final state = ref.read(contactsControllerProvider);
    if (state.status != ContactsStatus.error && mounted) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact added successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_alt_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Add contact',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: state.status == ContactsStatus.loading ? null : _save,
                icon: state.status == ContactsStatus.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(state.status == ContactsStatus.loading
                    ? 'Saving...'
                    : 'Save contact'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
