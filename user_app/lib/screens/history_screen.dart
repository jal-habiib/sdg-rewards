import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _userId = 'mama-alice';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Transaction History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('user_id', isEqualTo: _userId)
            .orderBy('created_at', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, color: Color(0xFF9CA3AF), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load history:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Color(0xFFD1D5DB), size: 48),
                    SizedBox(height: 14),
                    Text(
                      'No transactions yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scan a QR code to earn your first points.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final tx   = docs[i].data() as Map<String, dynamic>;
              final type = tx['type'] as String? ?? 'earn';
              final isEarn = type == 'earn';

              final pts = isEarn
                  ? '+${tx['points'] ?? 50}'
                  : '-${tx['points_spent'] ?? 50}';

              final label   = isEarn
                  ? (tx['code_id'] ?? 'Code scanned')
                  : (tx['reward_id'] ?? 'Reward redeemed');

              final partner = isEarn
                  ? (tx['campaign_id'] ?? '')
                  : (tx['partner_id']  ?? '');

              final ts = tx['created_at'] as Timestamp?;
              final timeStr = ts != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(ts.toDate().toLocal())
                  : '—';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    // ── Type icon ────────────────────────────────
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: isEarn ? const Color(0xFFE8F5E9) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEarn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isEarn ? const Color(0xFF2E7D32) : const Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Details ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEarn ? 'Earned Points' : 'Redeemed Reward',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (partner.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              partner,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB0B7C3)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Points + timestamp ─────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$pts pts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isEarn ? const Color(0xFF2E7D32) : const Color(0xFFDC2626),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
