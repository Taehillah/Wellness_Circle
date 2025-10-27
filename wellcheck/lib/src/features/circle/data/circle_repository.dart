import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';

import '../../contacts/application/contacts_controller.dart';
import '../../contacts/data/models/contact.dart';
import '../../../shared/settings/settings_controller.dart';
import '../data/models/circle_alert_summary.dart';
import '../data/models/circle_member.dart';
import '../data/models/circle_overview.dart';
import '../data/models/circle_stats.dart';

class CircleRepository {
  CircleRepository(this._ref, this._firestore);

  final Ref _ref;
  final FirebaseFirestore _firestore;

  bool get _hasRealProject {
    final projectId = _firestore.app.options.projectId;
    return !projectId.toLowerCase().contains('todo');
  }

  Stream<CircleOverview> watchOverview({
    required String circleId,
    int alertsLimit = 10,
  }) async* {
    if (!_hasRealProject) {
      yield* _buildFallbackOverview();
      return;
    }

    final membersCollection = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) =>
              snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
    final alertsCollection = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .limit(alertsLimit)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) =>
              snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );

    await for (final membersSnapshot in membersCollection.snapshots()) {
      final members = membersSnapshot.docs
          .map((doc) => CircleMember.fromFirestore(doc))
          .toList();
      final visibleMembers =
          members.where((member) => member.sharesActivity).toList();
      CircleStats stats = CircleStats.fromMembers(visibleMembers);
      List<CircleAlertSummary> alerts = const [];

      try {
        final alertSnapshot = await alertsCollection.get();
        alerts = alertSnapshot.docs
            .map((doc) => CircleAlertSummary.fromFirestore(doc))
            .toList();
        final latestAlert = alerts.isEmpty
            ? null
            : alerts
                  .map((alert) => alert.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b);
        stats = stats.copyWith(lastAlertAt: latestAlert);
      } catch (_) {
        // Fail silently – alerts are optional for overview.
      }

      yield CircleOverview(
        members: visibleMembers,
        stats: stats,
        alerts: alerts,
        isDemoData: false,
      );
    }
  }

  Stream<CircleOverview> _buildFallbackOverview() {
    final controller = StreamController<CircleOverview>();

    CircleOverview buildOverviewFromContacts(List<Contact> contacts) {
      final members = contacts.map(_mapContact).toList();
      final stats = CircleStats.fromMembers(members);
      return CircleOverview(
        members: members,
        stats: stats,
        alerts: const [],
        isDemoData: true,
      );
    }

    void emit(List<Contact> contacts) {
      if (!controller.isClosed) {
        controller.add(buildOverviewFromContacts(contacts));
      }
    }

    final initialContacts = _ref.read(contactsControllerProvider).contacts;
    emit(initialContacts);

    final preferredSub = _ref.listen<String?>(
      preferredContactProvider,
      (previous, next) => emit(_ref.read(contactsControllerProvider).contacts),
    );

    final contactsSub = _ref.listen<ContactsState>(
      contactsControllerProvider,
      (previous, next) => emit(next.contacts),
    );

    controller.onCancel = () {
      contactsSub.close();
      preferredSub.close();
      controller.close();
    };

    return controller.stream;
  }

  CircleMember _mapContact(Contact contact) {
    final isPreferred = _ref.read(preferredContactProvider) == contact.id;
    return CircleMember(
      id: contact.id,
      displayName: contact.name,
      role: CircleMemberRole.caregiver,
      status: _deriveStatus(contact),
      relationship: 'Family',
      phone: contact.phone,
      isPreferred: isPreferred,
      isManual: false,
      lastCheckInAt: contact.createdAt,
      lastAlertAt: null,
      sharesActivity: true,
    );
  }

  CircleMemberStatus _deriveStatus(Contact contact) {
    final hoursSinceCheckIn = DateTime.now()
        .difference(contact.createdAt)
        .inHours;
    if (hoursSinceCheckIn > 24) {
      return CircleMemberStatus.needsAttention;
    }
    return CircleMemberStatus.checkedIn;
  }
}

final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return CircleRepository(ref, firestore);
});
