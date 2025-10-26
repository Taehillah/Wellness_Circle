import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/models/circle_invite_payload.dart';

class CircleQrScannerPage extends ConsumerStatefulWidget {
  const CircleQrScannerPage({super.key});

  @override
  ConsumerState<CircleQrScannerPage> createState() =>
      _CircleQrScannerPageState();
}

class _CircleQrScannerPageState extends ConsumerState<CircleQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _processed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue?.trim();
    if (raw == null || raw.isEmpty) {
      setState(() {
        _errorMessage = 'Unable to read QR code. Try again.';
      });
      return;
    }
    final payload = CircleInvitePayload.decode(raw);
    final directCircleId = payload?.circleId ?? raw;
    if (directCircleId.isEmpty) {
      setState(() {
        _errorMessage = 'This doesn’t look like a Wellness Circle invite.';
      });
      return;
    }
    _processed = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan circle QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surface.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Point your camera at the QR code your loved one shared.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
