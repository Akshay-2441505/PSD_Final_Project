import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';

class LoanStatusScreen extends StatefulWidget {
  final String loanId;
  const LoanStatusScreen({super.key, required this.loanId});
  @override State<LoanStatusScreen> createState() => _LoanStatusScreenState();
}

class _LoanStatusScreenState extends State<LoanStatusScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _loan;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final loan = await _api.getLoanStatus(widget.loanId, token);
      if (mounted) setState(() { _loan = loan; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _loan == null
              ? const Center(child: Text('Unable to load loan details'))
              : ListView(padding: const EdgeInsets.all(20), children: [
                  // ── Status Card ────────────────────────────────────
                  _StatusCard(loan: _loan!),
                  const SizedBox(height: 20),

                  // ── State Machine Timeline ─────────────────────────
                  _StatusTimeline(status: _loan!['status'] as String),
                  const SizedBox(height: 20),

                  // ── Loan Details ───────────────────────────────────
                  _DetailCard(loan: _loan!),
                  const SizedBox(height: 20),

                  // ── Admin Remarks ──────────────────────────────────
                  if (_loan!['admin_remarks'] != null && (_loan!['admin_remarks'] as String).isNotEmpty)
                    _RemarksCard(remarks: _loan!['admin_remarks']),

                  // ── Risk Info ──────────────────────────────────────
                  if (_loan!['risk_score'] != null) ...[
                    const SizedBox(height: 20),
                    _RiskCard(score: _loan!['risk_score'], flags: List<String>.from(_loan!['risk_flags'] ?? [])),
                  ],
                ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _StatusCard({required this.loan});

  Color _color(String s) => switch (s) {
    'APPROVED'     => kSuccess,
    'REJECTED'     => kError,
    'PENDING'      => kWarning,
    'UNDER_REVIEW' => Colors.blue,
    _              => kTextMuted,
  };

  IconData _icon(String s) => switch (s) {
    'APPROVED'     => Icons.check_circle_rounded,
    'REJECTED'     => Icons.cancel_rounded,
    'PENDING'      => Icons.schedule_rounded,
    'UNDER_REVIEW' => Icons.manage_search_rounded,
    _              => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] as String;
    final color  = _color(status);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(_icon(status), color: color, size: 48),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(status.replaceAll('_', ' '),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text('Loan Application #${(loan['app_id'] as String).substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 4),
          Text('₹ ${loan['requested_amount']} for ${loan['tenure_months']} months',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
        ])),
      ]),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = ['DRAFT', 'PENDING', 'UNDER_REVIEW', 'APPROVED'];

  int _stepIndex(String s) {
    if (s == 'REJECTED') return 2;
    return _steps.indexOf(s).clamp(0, _steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final current = _stepIndex(status);
    final isRejected = status == 'REJECTED';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Application Journey', style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: _steps.asMap().entries.map((e) {
          final done   = e.key <= current;
          final active = e.key == current;
          final color  = isRejected && e.key == 2 ? kError : done ? kPrimary : const Color(0xFFE0E0E0);
          return Expanded(child: Column(children: [
            Row(children: [
              if (e.key > 0) Expanded(child: Container(height: 2, color: e.key <= current ? kPrimary : const Color(0xFFE0E0E0))),
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(active && isRejected ? Icons.close : done ? Icons.check : Icons.circle,
                    color: Colors.white, size: 14)),
              if (e.key < _steps.length - 1) Expanded(child: Container(height: 2, color: e.key < current ? kPrimary : const Color(0xFFE0E0E0))),
            ]),
            const SizedBox(height: 6),
            Text(e.value.replaceAll('_', ' '), style: TextStyle(fontSize: 9, color: done ? kPrimary : kTextMuted),
                textAlign: TextAlign.center),
          ]));
        }).toList()),
      ]),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _DetailCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Application Details', style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 14)),
        const SizedBox(height: 16),
        _Row('Amount', '₹ ${loan['requested_amount']}'),
        _Row('Tenure', '${loan['tenure_months']} months'),
        _Row('Purpose', (loan['purpose'] as String).replaceAll('_', ' ')),
        _Row('Turnover', '₹ ${loan['declared_turnover'] ?? 'Not declared'}'),
        _Row('Profit',   '₹ ${loan['declared_profit'] ?? 'Not declared'}'),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
      Text(value,  style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _RemarksCard extends StatelessWidget {
  final String remarks;
  const _RemarksCard({required this.remarks});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.comment_outlined, color: kTextMuted, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Admin Remarks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kTextMuted)),
        const SizedBox(height: 4),
        Text(remarks, style: const TextStyle(fontSize: 13, color: kTextDark)),
      ])),
    ]),
  );
}

class _RiskCard extends StatelessWidget {
  final int score;
  final List<String> flags;
  const _RiskCard({required this.score, required this.flags});
  @override Widget build(BuildContext context) {
    final color = score >= 70 ? kSuccess : score >= 45 ? kWarning : kError;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Risk Assessment', style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 14)),
        const SizedBox(height: 12),
        Row(children: [
          CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.15),
              child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(score >= 70 ? 'Low Risk' : score >= 45 ? 'Medium Risk' : 'High Risk',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            Text('Risk Score out of 100', style: const TextStyle(fontSize: 11, color: kTextMuted)),
          ]),
        ]),
        if (flags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: flags.map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kError.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(f.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: kError)),
          )).toList()),
        ],
      ]),
    );
  }
}
