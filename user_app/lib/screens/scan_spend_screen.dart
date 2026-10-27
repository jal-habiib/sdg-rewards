import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

const _kApiBase = 'https://sdg-rewards.onrender.com';

class ScanSpendScreen extends StatefulWidget {
  const ScanSpendScreen({super.key});

  @override
  State<ScanSpendScreen> createState() => _ScanSpendScreenState();
}

class _ScanSpendScreenState extends State<ScanSpendScreen> {
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
        message: 'This QR code is not a valid SDG Rewards partner spend code.',
      );
      return;
    }

    // Validate it is a spend-type code
    if (parsed['type'] != 'spend') {
      _showResult(
        success: false,
        title: 'Wrong QR Type',
        message: 'Please scan a partner spend QR code, not an earn code.',
      );
      return;
    }

    setState(() { _processing = true; _scanned = true; });
    await _controller?.stop();

    try {
      final response = await http.post(
        Uri.parse('$_kApiBase/api/spend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':   'mama-alice',
          'reward_id': parsed['reward_id'],
          'partner_id': parsed['partner_id'],
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final pointsSpent = body['points_spent'] ?? 50;
        final ugx         = body['ugx_disbursed'] ?? 2000;
        _showResult(
          success: true,
          title: 'Discount Applied!',
          message: 'You redeemed $pointsSpent points.\nValue: ${_fmtUgx(ugx)} UGX off your purchase.',
        );
      } else {
        _showResult(
          success: false,
          title: 'Redemption Failed',
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

  String _fmtUgx(dynamic value) {
    if (value == null) return '0';
    final n = (value as num).toInt();
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
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
                Navigator.pop(context); // back to wallet
              } else {
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
        title: const Text('Spend Points', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                    'Scan the partner QR code at checkout',
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
                    Text('Applying discount...', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
