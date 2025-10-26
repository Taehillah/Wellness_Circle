import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_theme.dart';
import '../application/emergency_controller.dart';
import '../../../shared/services/geolocation_service.dart';
import '../data/models/help_location.dart';

class NeedHelpSheet extends ConsumerStatefulWidget {
  const NeedHelpSheet({super.key});

  @override
  ConsumerState<NeedHelpSheet> createState() => _NeedHelpSheetState();
}

class _NeedHelpSheetState extends ConsumerState<NeedHelpSheet> {
  final _messageController = TextEditingController();
  bool _requestedLocation = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLocation) {
      _requestedLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(emergencyControllerProvider.notifier).refreshLocation();
      });
    }
  }

  Future<void> _sendHelp() async {
    final controller = ref.read(emergencyControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await controller.sendHelp(
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );
    final state = ref.read(emergencyControllerProvider);
    if (mounted && state.errorMessage == null) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(state.statusMessage ?? 'Help request sent!')),
      );
      _messageController.clear();
      controller.clearStatus();
    }
  }

  String _coordLabel(HelpLocation location) =>
      'Lat ${location.lat.toStringAsFixed(4)}, Lng ${location.lng.toStringAsFixed(4)}';

  String _locationSummary(EmergencyState state) {
    final location = state.location;
    if (location == null) {
      return _locationMessage(state);
    }
    final address = location.address?.trim();
    final coords = _coordLabel(location);
    if (address == null || address.isEmpty) {
      return coords;
    }
    if (address == coords) {
      return coords;
    }
    return '$address\n$coords';
  }

  Future<void> _openDirections(HelpLocation location) async {
    final lat = location.lat;
    final lng = location.lng;
    final google = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    final apple = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
    final primary = defaultTargetPlatform == TargetPlatform.iOS
        ? apple
        : google;
    final fallback = defaultTargetPlatform == TargetPlatform.iOS
        ? google
        : apple;

    Future<bool> launchExternal(Uri uri) async {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (await launchExternal(primary)) return;
    if (await launchExternal(fallback)) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open a maps app on this device.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.sos_outlined, color: AppColors.danger),
                const SizedBox(width: 12),
                Text(
                  'Emergency request',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Optional note',
                alignLabelWithHint: true,
                hintText: 'Share what you\'re experiencing right now...',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.12 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 20,
                        color: state.hasLocation
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.hasLocation
                            ? 'Location attached'
                            : 'Location unavailable',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationSummary(state),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.isLocating
                            ? null
                            : () => ref
                                  .read(emergencyControllerProvider.notifier)
                                  .refreshLocation(),
                        icon: state.isLocating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Refresh location'),
                      ),
                      if (state.location != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openDirections(state.location!),
                          icon: const Icon(Icons.directions_car_outlined),
                          label: const Text('Drive'),
                        ),
                      ],
                    ],
                  ),
                ],
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
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                elevation: 4,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: state.isSending ? null : _sendHelp,
              icon: state.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sos_rounded, size: 22),
              label: Text(
                state.isSending ? 'Sending...' : 'Send help request',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _locationMessage(EmergencyState state) {
    if (state.permissionStatus == GeoPermissionStatus.serviceDisabled) {
      return 'Enable location services to send your location.';
    }
    if (state.permissionDenied) {
      return 'Location permission denied. You can still send a request without it.';
    }
    return 'We will attach your GPS coordinates when available.';
  }
}
