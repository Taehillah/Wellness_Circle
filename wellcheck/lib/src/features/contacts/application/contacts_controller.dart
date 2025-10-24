import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../../shared/data/seed_data.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_session.dart';
import '../data/contacts_repository.dart';
import '../data/models/contact.dart';

class ContactsState {
  const ContactsState({
    required this.contacts,
    required this.status,
    this.errorMessage,
  });

  final List<Contact> contacts;
  final ContactsStatus status;
  final String? errorMessage;

  ContactsState copyWith({
    List<Contact>? contacts,
    ContactsStatus? status,
    String? errorMessage,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  factory ContactsState.initial() => const ContactsState(
        contacts: [],
        status: ContactsStatus.idle,
      );
}

enum ContactsStatus { idle, loading, ready, error }

class ContactsController extends Notifier<ContactsState> {
  late final ContactsRepository _repository;
  AuthSession? _session;

  @override
  ContactsState build() {
    _repository = ref.read(contactsRepositoryProvider);
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      unawaited(onSessionChanged(next));
    }, fireImmediately: true);
    return ContactsState.initial();
  }

  Future<void> onSessionChanged(AuthSession? session) async {
    _session = session;
    if (session == null) {
      state = ContactsState.initial();
      return;
    }

    state = state.copyWith(status: ContactsStatus.loading, errorMessage: null);
    try {
      final seeded = _buildSeededContacts(session.user.email);
      final contacts = await _repository.loadContacts(
        userId: session.user.id,
        seeded: seeded,
      );
      state = state.copyWith(
        contacts: contacts,
        status: ContactsStatus.ready,
      );
    } catch (error) {
      state = state.copyWith(
        status: ContactsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> addContact(String name, String phone) async {
    final session = _session;
    if (session == null) {
      return;
    }
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
      state = state.copyWith(
        status: ContactsStatus.error,
        errorMessage: 'Name and phone number are required.',
      );
      return;
    }
    state = state.copyWith(status: ContactsStatus.loading, errorMessage: null);
    try {
      final contact = await _repository.addContact(
        userId: session.user.id,
        current: state.contacts,
        name: trimmedName,
        phone: trimmedPhone,
      );
      final next = [...state.contacts, contact];
      state = state.copyWith(
        contacts: next,
        status: ContactsStatus.ready,
      );
    } catch (error) {
      state = state.copyWith(
        status: ContactsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> removeContact(String id) async {
    final session = _session;
    if (session == null) {
      return;
    }
    state = state.copyWith(status: ContactsStatus.loading, errorMessage: null);
    try {
      await _repository.removeContact(
        userId: session.user.id,
        current: state.contacts,
        contactId: id,
      );
      final next = state.contacts.where((contact) => contact.id != id).toList();
      state = state.copyWith(
        contacts: next,
        status: ContactsStatus.ready,
      );
    } catch (error) {
      state = state.copyWith(
        status: ContactsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  List<Contact> _buildSeededContacts(String email) {
    if (!SeedData.shouldSeed(email)) {
      return const [];
    }
    return SeedData.seededContacts(email)
        .map(
          (seed) => Contact(
            id: seed['name']!,
            name: seed['name']!,
            phone: seed['phone']!,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> refresh() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await onSessionChanged(session);
  }
}

final contactsControllerProvider =
    NotifierProvider<ContactsController, ContactsState>(ContactsController.new);
