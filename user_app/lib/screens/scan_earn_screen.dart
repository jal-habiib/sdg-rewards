import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

const _kApiBase = 'http://localhost:3000';

class ScanEarnScreen extends StatefulWidget {
  const ScanEarnScreen({super.key});

  @override
  State<ScanEarnScreen> createState() => _ScanEarnScreenState();
}

class _ScanEarnScreenState extends State<ScanEarnScreen> {
  MobileScannerController? _controller;
  bool _processing = false;
  bool _scanned    = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final rawString = barcode!.rawValue!;

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(rawString) as Map<String, dynamic>;
    } catch (_) {
      _showResult(
        success: false,
        title: 'Invalid QR Code',
        message: 'This QR code is not a valid SDG Rewards earn code.',
      );
      return;
    }

    setState(() { _processing = true; _scanned = true; });
    await _controller?.stop();

    try {
      final response = await http.post(
        Uri.parse('$_kApiBase/api/earn'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'mama-alice',
          'code_id': parsed['code'],
          'qr_data': parsed,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        _showResult(
          success: true,
          title: 'Points Earned!',
          message: body['message'] ?? 'You earned ${body['points_awarded'] ?? 50} nutrition points.',
        );
      } else {
        _showResult(
          success: false,
          title: 'Could Not Earn Points',
          message: body['error'] ?? 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      _showResult(
        success: false,
        title: 'Network Error',
        message: 'Could not reach the server. Please check your connection.',
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showResult({required bool success, required String title, required String message}) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: success ? const Color(0xFFE8F5E9) : const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? const Color(0xFF2E7D32) : const Color(0xFFDC2626),
            size: 28,
          ),
        ),
        title: Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
            onPressed: () {
              Navigator.pop(ctx);
              if (success) {
                Navigator.pop(context); // return to wallet
              } else {
                // allow re-scan
                setState(() => _scanned = false);
                _controller?.start();
              }
            },
            child: Text(success ? 'Done' : 'Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan to Earn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ── Scanner ────────────────────────────────────────────
          MobileScanner(controller: _controller!, onDetect: _onDetect),

          // ── Viewfinder overlay ─────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Point camera at a product QR code',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading overlay ────────────────────────────────────
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 16),
                    Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
