import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/application/auth_controller.dart';
import '../data/circle_membership_repository.dart';
import '../data/models/circle_invite_payload.dart';
import 'circle_qr_scanner_page.dart';

class CircleJoinSheet extends ConsumerStatefulWidget {
  const CircleJoinSheet({super.key});

  @override
  ConsumerState<CircleJoinSheet> createState() => _CircleJoinSheetState();
}

class _CircleJoinSheetState extends ConsumerState<CircleJoinSheet> {
  final _inviteCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePasteInvite() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _inviteCodeController.text = text;
    });
    await _attemptJoin();
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const CircleQrScannerPage(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      _inviteCodeController.text = result;
      await _attemptJoin();
    }
  }

  Future<void> _attemptJoin() async {
    if (_isJoining) return;
    final circleId = await _resolveCircleId();
    if (circleId == null) {
      setState(() {
        _error =
            'We could not determine a circle from the details provided. Try scanning a QR code or double check the email.';
      });
      return;
    }
    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final session = ref.read(authSessionProvider);
      if (session == null) {
        throw Exception('Log in before joining a circle.');
      }
      final repository = ref.read(circleMembershipRepositoryProvider);
      await repository.joinCircle(session: session, circleId: circleId);
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Joined circle $circleId successfully.')),
      );
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<String?> _resolveCircleId() async {
    final invite = _inviteCodeController.text.trim();
    if (invite.isNotEmpty) {
      final payload = CircleInvitePayload.decode(invite);
      if (payload != null) {
        return payload.circleId;
      }
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final repository = ref.read(circleMembershipRepositoryProvider);
      final result = await repository.findCircleIdByEmail(email);
      if (result != null) return result;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      final repository = ref.read(circleMembershipRepositoryProvider);
      final result = await repository.findCircleIdByPhone(phone);
      if (result != null) return result;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider);
    final canJoin = session != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Join a circle',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canJoin
                    ? 'Scan their QR code or share their email/phone to connect.'
                    : 'Log in to join a circle and stay connected.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (!canJoin) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'You must be signed in to join a circle.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (!canJoin || _isJoining) ? null : _openScanner,
                      icon: const Icon(LucideIcons.scanLine),
                      label: const Text('Scan QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (!canJoin || _isJoining)
                          ? null
                          : _handlePasteInvite,
                      icon: const Icon(Icons.paste),
                      label: const Text('Paste code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(
                  labelText: 'Invite code',
                  hintText: 'Paste code from QR or message',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'OR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Their email address',
                  hintText: 'friend@example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Their phone number',
                  hintText: '+1234567890',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (!canJoin || _isJoining) ? null : _attemptJoin,
                icon: _isJoining
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.group_add_outlined),
                label: Text(_isJoining ? 'Joining...' : 'Join circle'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
