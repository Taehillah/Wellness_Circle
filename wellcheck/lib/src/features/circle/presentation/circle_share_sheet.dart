import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../data/circle_membership_repository.dart';
import '../data/models/circle_invite_payload.dart';

class CircleShareSheet extends ConsumerStatefulWidget {
  const CircleShareSheet({super.key});

  @override
  ConsumerState<CircleShareSheet> createState() => _CircleShareSheetState();
}

class _CircleShareSheetState extends ConsumerState<CircleShareSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = ref.read(authSessionProvider);
      if (session == null) return;
      final repository = ref.read(circleMembershipRepositoryProvider);
      await repository.ensureCircleExists(
        circleId: session.user.circleId ?? 'circle-${session.user.id}',
        owner: session,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final circleId = session?.user.circleId ?? 'circle-demo';
    final ownerEmail = session?.user.email ?? 'member@demo.app';
    final payload = CircleInvitePayload(
      circleId: circleId,
      ownerEmail: ownerEmail,
    );
    final code = payload.encode();
    final inviteText = 'wellcheck://join?code=$code';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share your circle',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask loved ones to scan this code or use your email to join.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: code,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                  size: 220,
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(48, 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(label: 'Circle ID', value: circleId),
              const SizedBox(height: 8),
              _InfoTile(label: 'Share email', value: ownerEmail),
              const SizedBox(height: 8),
              _InfoTile(label: 'Invite link', value: inviteText),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite code copied to clipboard.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy invite code'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final sharePayload = jsonEncode({
                    'circleId': circleId,
                    'email': ownerEmail,
                    'code': code,
                  });
                  await Clipboard.setData(ClipboardData(text: sharePayload));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invite details copied. Share via chat or email.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Copy full invite details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
