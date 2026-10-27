import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _leafSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 3C21 3 14 3 9 8C4 13 3 21 3 21C3 21 8 20 11 17C14 14 14 10 14 10C14 10 18 10 21 7C22.5 5.5 21 3 21 3Z"
    fill="#2E7D32" opacity="0.2"/>
  <path d="M21 3C21 3 14 3 9 8C4 13 3 21 3 21C3 21 8 20 11 17C14 14 14 10 14 10C14 10 18 10 21 7C22.5 5.5 21 3 21 3Z"
    stroke="#2E7D32" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M3 21L10 14" stroke="#2E7D32" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();

  bool _codeSent  = false;
  bool _loading   = false;
  String? _error;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter a phone number.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-retrieval
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _loading = false;
          _error = e.message ?? 'Verification failed.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _loading     = false;
          _codeSent    = true;
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _verificationId == null) {
      setState(() => _error = 'Please enter the OTP sent to your phone.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message ?? 'Invalid OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Brand ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: SvgPicture.string(_leafSvg),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'SDG Rewards',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SDG 2: Zero Hunger — Nutrition Program',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Card ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _codeSent ? 'Enter verification code' : 'Sign in with phone',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _codeSent
                            ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                            : 'We\'ll send a one-time code to your number.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                      ),
                      const SizedBox(height: 22),

                      // Phone field (always visible)
                      TextField(
                        controller: _phoneController,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '+256 7XX XXX XXX',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      ),

                      if (_codeSent) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Verification code',
                            hintText: '6-digit OTP',
                            counterText: '',
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      _loading
                          ? const Center(
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _codeSent ? _verifyOtp : _sendCode,
                              child: Text(_codeSent ? 'Verify & Sign In' : 'Send Code'),
                            ),

                      if (_codeSent) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading ? null : () {
                            setState(() { _codeSent = false; _error = null; _otpController.clear(); });
                          },
                          child: const Text('Change phone number', style: TextStyle(color: Color(0xFF6B7280))),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
