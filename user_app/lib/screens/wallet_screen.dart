import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'scan_earn_screen.dart';
import 'scan_spend_screen.dart';
import 'history_screen.dart';

const _leafSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 3C21 3 14 3 9 8C4 13 3 21 3 21C3 21 8 20 11 17C14 14 14 10 14 10C14 10 18 10 21 7C22.5 5.5 21 3 21 3Z"
    fill="#2E7D32" opacity="0.2"/>
  <path d="M21 3C21 3 14 3 9 8C4 13 3 21 3 21C3 21 8 20 11 17C14 14 14 10 14 10C14 10 18 10 21 7C22.5 5.5 21 3 21 3Z"
    stroke="#2E7D32" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M3 21L10 14" stroke="#2E7D32" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _balanceDocId = 'mama-alice_nutrition';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            SizedBox(
              width: 22, height: 22,
              child: SvgPicture.string(_leafSvg),
            ),
            const SizedBox(width: 10),
            const Text(
              'SDG Rewards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF6B7280)),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Balance Card ───────────────────────────────────
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('balances')
                    .doc(_balanceDocId)
                    .snapshots(),
                builder: (context, snapshot) {
                  int points = 0;
                  bool loading = snapshot.connectionState == ConnectionState.waiting;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    points = (data?['points'] as num?)?.toInt() ?? 0;
                  }

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20, height: 20,
                              child: SvgPicture.string(
                                _leafSvg.replaceAll('#2E7D32', 'white').replaceAll('opacity="0.2"', 'opacity="0.5"'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Nutrition Points',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (loading)
                              const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white54, strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(points * 40).toStringAsFixed(0)} UGX equivalent',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Section label ──────────────────────────────────
              const Text(
                'ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 12),

              // ── Scan to Earn button ────────────────────────────
              _ActionTile(
                title: 'Scan to Earn',
                subtitle: 'Scan a product QR code to earn nutrition points',
                icon: Icons.qr_code_scanner_outlined,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanEarnScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // ── Spend Points button ────────────────────────────
              _ActionTile(
                title: 'Spend Points',
                subtitle: 'Scan a partner QR code to redeem a discount',
                icon: Icons.storefront_outlined,
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanSpendScreen()),
                ),
              ),
              const SizedBox(height: 28),

              // ── History link ───────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  icon: const Icon(Icons.history, size: 16, color: Color(0xFF2E7D32)),
                  label: const Text(
                    'View Transaction History',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
