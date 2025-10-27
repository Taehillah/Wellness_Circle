import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/preferences_service.dart';
import 'models/contact.dart';

class ContactsRepository {
  ContactsRepository(this._preferences, this._firestore, this._auth);

  final PreferencesService _preferences;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  String _key(int userId) => 'wellcheck.user.$userId.contacts';

  CollectionReference<Map<String, dynamic>>? _userContactsCollection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('contacts');
  }

  Future<List<Contact>> _loadFromFirestore({required int userId}) async {
    final collection = _userContactsCollection();
    if (collection == null) {
      return const [];
    }
    final snapshot = await collection
        .orderBy('createdAt', descending: false)
        .get();
    final contacts = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return Contact.fromJson(data);
    }).toList();
    // Cache locally for offline access.
    await saveContacts(userId: userId, contacts: contacts);
    return contacts;
  }

  Future<List<Contact>> loadContacts({
    required int userId,
    List<Contact> seeded = const [],
  }) async {
    try {
      final contacts = await _loadFromFirestore(userId: userId);
      if (contacts.isEmpty && seeded.isNotEmpty) {
        await _seedContacts(userId: userId, contacts: seeded);
        return seeded;
      }
      return contacts;
    } catch (_) {
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
          .map(
            (item) => Contact.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
  }

  Future<void> _seedContacts({
    required int userId,
    required List<Contact> contacts,
  }) async {
    final collection = _userContactsCollection();
    if (collection != null) {
      final batch = _firestore.batch();
      for (final contact in contacts) {
        final ref = collection.doc(contact.id);
        batch.set(ref, {
          'id': contact.id,
          'name': contact.name,
          'phone': contact.phone,
          'createdAt': contact.createdAt.toIso8601String(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
    await saveContacts(userId: userId, contacts: contacts);
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

    final collection = _userContactsCollection();
    if (collection != null) {
      await collection.doc(contact.id).set({
        'id': contact.id,
        'name': contact.name,
        'phone': contact.phone,
        'createdAt': contact.createdAt.toIso8601String(),
      }, SetOptions(merge: true));
    }
    return contact;
  }

  Future<void> removeContact({
    required int userId,
    required List<Contact> current,
    required String contactId,
  }) async {
    final next = current.where((c) => c.id != contactId).toList();
    await saveContacts(userId: userId, contacts: next);
    final collection = _userContactsCollection();
    if (collection != null) {
      await collection.doc(contactId).delete().catchError((_) {});
    }
  }

  Future<void> clearContacts(int userId) async {
    await _preferences.remove(_key(userId));
    final collection = _userContactsCollection();
    if (collection != null) {
      final batch = _firestore.batch();
      final snapshot = await collection.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return ContactsRepository(preferences, firestore, auth);
});
