import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/preferences_service.dart';
import 'models/contact.dart';

class ContactsRepository {
  ContactsRepository(this._preferences);

  final PreferencesService _preferences;
  final _uuid = const Uuid();

  String _key(int userId) => 'wellcheck.user.$userId.contacts';

  Future<List<Contact>> loadContacts({
    required int userId,
    List<Contact> seeded = const [],
  }) async {
    final raw = _preferences.getString(_key(userId));
    if (raw == null) {
      if (seeded.isNotEmpty) {
        await saveContacts(userId: userId, contacts: seeded);
        return seeded;
      }
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Contact.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveContacts({
    required int userId,
    required List<Contact> contacts,
  }) async {
    final payload = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await _preferences.setString(_key(userId), payload);
  }

  Future<Contact> addContact({
    required int userId,
    required List<Contact> current,
    required String name,
    required String phone,
  }) async {
    final contact = Contact(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    final next = [...current, contact];
    await saveContacts(userId: userId, contacts: next);
    return contact;
  }

  Future<void> removeContact({
    required int userId,
    required List<Contact> current,
    required String contactId,
  }) async {
    final next = current.where((c) => c.id != contactId).toList();
    await saveContacts(userId: userId, contacts: next);
  }

  Future<void> clearContacts(int userId) async {
    await _preferences.remove(_key(userId));
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  return ContactsRepository(preferences);
});
