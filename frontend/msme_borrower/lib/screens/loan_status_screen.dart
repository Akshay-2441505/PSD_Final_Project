import 'dart:math';
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

class _LoanStatusScreenState extends State<LoanStatusScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _loan;
  bool _loading = true;

  late final AnimationController _celebCtrl;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _load();
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final loan = await _api.getLoanStatus(widget.loanId, token);
      if (mounted) {
        setState(() { _loan = loan; _loading = false; });
        if (loan['status'] == 'APPROVED') {
          Future.delayed(const Duration(milliseconds: 300), _checkCtrl.forward);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE))),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: kTextDark),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _loan == null
              ? const Center(child: Text('Unable to load loan details'))
              : Stack(children: [
                  // Confetti particles for APPROVED
                  if (_loan!['status'] == 'APPROVED')
                    AnimatedBuilder(
                      animation: _celebCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _ConfettiPainter(_celebCtrl.value),
                        child: const SizedBox.expand(),
                      ),
                    ),

                  ListView(padding: const EdgeInsets.all(20), children: [
                    // ── Hero Status Card ────────────────────────────────
                    _HeroStatusCard(loan: _loan!, checkAnim: _checkScale),
                    const SizedBox(height: 20),

                    // ── Journey Timeline ─────────────────────────────────
                    _JourneyTimeline(status: _loan!['status'] as String),
                    const SizedBox(height: 20),

                    // ── Loan Details Card ────────────────────────────────
                    _DetailCard(loan: _loan!),
                    const SizedBox(height: 20),

                    // ── Admin Remarks ────────────────────────────────────
                    if (_loan!['admin_remarks'] != null &&
                        (_loan!['admin_remarks'] as String).isNotEmpty) ...[ 
                      _RemarksCard(remarks: _loan!['admin_remarks']),
                      const SizedBox(height: 20),
                    ],

                    // ── Risk Card ────────────────────────────────────────
                    if (_loan!['risk_score'] != null)
                      _RiskCard(
                        score: _loan!['risk_score'] as int,
                        flags: List<String>.from(_loan!['risk_flags'] ?? []),
                      ),

                    // ── Rejected CTA ─────────────────────────────────────
                    if (_loan!['status'] == 'REJECTED') ...[ 
                      const SizedBox(height: 20),
                      _RejectedCta(),
                    ],
                    const SizedBox(height: 40),
                  ]),
                ]),
    );
  }
}

// ── Hero Status Card ──────────────────────────────────────────────────────────
class _HeroStatusCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final Animation<double> checkAnim;
  const _HeroStatusCard({required this.loan, required this.checkAnim});

  Color _color(String s) => switch (s) {
    'APPROVED'     => kSuccess,
    'REJECTED'     => kError,
    'PENDING'      => kWarning,
    'UNDER_REVIEW' => const Color(0xFF2196F3),
    _              => kTextMuted,
  };

  IconData _icon(String s) => switch (s) {
    'APPROVED'     => Icons.check_circle_rounded,
    'REJECTED'     => Icons.cancel_rounded,
    'PENDING'      => Icons.schedule_rounded,
    'UNDER_REVIEW' => Icons.manage_search_rounded,
    _              => Icons.info_rounded,
  };

  String _fmtAmount(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    return n >= 100000 ? '₹${(n / 100000).toStringAsFixed(1)}L' : '₹${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] as String;
    final color  = _color(status);
    final isApproved = status == 'APPROVED';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: isApproved
            ? LinearGradient(colors: [const Color(0xFF388E3C), const Color(0xFF4CAF50)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: isApproved ? null : Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isApproved
            ? [BoxShadow(color: kSuccess.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Animated icon for approved
          isApproved
              ? ScaleTransition(
                  scale: checkAnim,
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 52),
                )
              : status == 'PENDING'
                  ? _PulsingIcon(icon: _icon(status), color: color)
                  : Icon(_icon(status), color: isApproved ? Colors.white : color, size: 52),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              isApproved ? '🎉 Congratulations!' : status.replaceAll('_', ' '),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: isApproved ? Colors.white : color),
            ),
            const SizedBox(height: 4),
            Text(
              'Application #${(loan['app_id'] as String).substring(0, 8).toUpperCase()}',
              style: TextStyle(
                  fontSize: 12,
                  color: isApproved ? Colors.white70 : kTextMuted),
            ),
          ])),
        ]),
        const SizedBox(height: 16),
        Text(
          _fmtAmount(loan['requested_amount']),
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: isApproved ? Colors.white : kTextDark),
        ),
        Text(
          '${loan['tenure_months']} months • ${(loan['purpose'] as String).replaceAll('_', ' ')}',
          style: TextStyle(
              fontSize: 13,
              color: isApproved ? Colors.white70 : kTextMuted),
        ),
        if (isApproved) ...[ 
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Your funds will be disbursed within 2-3 business days',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ]),
    );
  }
}

// Pulsing icon for PENDING state
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});
  @override State<_PulsingIcon> createState() => _PulsingIconState();
}
class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ScaleTransition(
    scale: _anim,
    child: Icon(widget.icon, color: widget.color, size: 52),
  );
}

// ── Journey Timeline ──────────────────────────────────────────────────────────
class _JourneyTimeline extends StatelessWidget {
  final String status;
  const _JourneyTimeline({required this.status});

  static const _steps = [
    ('DRAFT', Icons.edit_note_rounded, 'Applied'),
    ('PENDING', Icons.hourglass_top_rounded, 'Pending'),
    ('UNDER_REVIEW', Icons.manage_search_rounded, 'In Review'),
    ('APPROVED', Icons.check_rounded, 'Approved'),
  ];

  int _idx(String s) {
    if (s == 'REJECTED') return 2;
    return _steps.indexWhere((e) => e.$1 == s).clamp(0, _steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final current     = _idx(status);
    final isRejected  = status == 'REJECTED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Application Journey',
            style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 15)),
        const SizedBox(height: 20),
        Row(
          children: _steps.asMap().entries.map((e) {
            final i       = e.key;
            final done    = i <= current;
            final active  = i == current;
            final rejected = isRejected && i == 2;
            final clr = rejected ? kError : done ? kPrimary : const Color(0xFFE0E0E0);

            return Expanded(child: Column(children: [
              Row(children: [
                if (i > 0)
                  Expanded(child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= current ? kPrimary : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: active ? 36 : 30,
                  height: active ? 36 : 30,
                  decoration: BoxDecoration(
                    color: clr,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [BoxShadow(color: clr.withOpacity(0.4), blurRadius: 12)]
                        : null,
                  ),
                  child: Icon(rejected ? Icons.close_rounded : e.value.$2,
                      color: Colors.white, size: active ? 18 : 15),
                ),
                if (i < _steps.length - 1)
                  Expanded(child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < current ? kPrimary : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              ]),
              const SizedBox(height: 8),
              Text(e.value.$3,
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: done ? kPrimary : kTextMuted),
                  textAlign: TextAlign.center),
            ]));
          }).toList(),
        ),
      ]),
    );
  }
}

// ── Detail Card ────────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _DetailCard({required this.loan});

  String _fmtAmount(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    return n >= 100000 ? '₹${(n / 100000).toStringAsFixed(1)}L' : '₹${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Application Details',
          style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 15)),
      const SizedBox(height: 16),
      _Row('Amount', _fmtAmount(loan['requested_amount'])),
      _Row('Tenure', '${loan['tenure_months']} months'),
      _Row('Purpose', (loan['purpose'] as String).replaceAll('_', ' ')),
      _Row('Turnover', _fmtAmount(loan['declared_turnover'] ?? 0)),
      _Row('Profit',   _fmtAmount(loan['declared_profit'] ?? 0)),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
      Text(value,
          style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Remarks Card ───────────────────────────────────────────────────────────────
class _RemarksCard extends StatelessWidget {
  final String remarks;
  const _RemarksCard({required this.remarks});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kAccent.withOpacity(0.5), width: 1.5),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
            color: Color(0xFFFFD18C), shape: BoxShape.circle),
        child: const Icon(Icons.format_quote_rounded, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Admin Remarks',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kTextMuted)),
        const SizedBox(height: 4),
        Text(remarks, style: const TextStyle(fontSize: 13, color: kTextDark, height: 1.4)),
      ])),
    ]),
  );
}

// ── Risk Card ──────────────────────────────────────────────────────────────────
class _RiskCard extends StatelessWidget {
  final int score;
  final List<String> flags;
  const _RiskCard({required this.score, required this.flags});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? kSuccess : score >= 45 ? kWarning : kError;
    final label = score >= 70 ? 'Low Risk' : score >= 45 ? 'Moderate Risk' : 'High Risk';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Risk Assessment',
            style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 15)),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text('$score',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            const Text('Credit Risk Score / 100',
                style: TextStyle(fontSize: 11, color: kTextMuted)),
          ]),
          const Spacer(),
          SizedBox(
            width: 80, height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ]),
        if (flags.isNotEmpty) ...[ 
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 6,
            children: flags.map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: kError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kError.withOpacity(0.3))),
              child: Text(f.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 11, color: kError, fontWeight: FontWeight.w600)),
            )).toList()),
        ],
      ]),
    );
  }
}

// ── Rejected CTA ───────────────────────────────────────────────────────────────
class _RejectedCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
    ),
    child: Column(children: [
      const Icon(Icons.support_agent_rounded, color: kPrimary, size: 36),
      const SizedBox(height: 10),
      const Text("Don't give up!",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextDark)),
      const SizedBox(height: 6),
      const Text(
          "Improve your credit score, declare higher turnover, or apply for a smaller amount. Our advisors can help.",
          style: TextStyle(fontSize: 12, color: kTextMuted, height: 1.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, height: 46,
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: const BorderSide(color: kPrimary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text('Talk to an Advisor',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );
}

// ── Confetti Painter ─────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _rng = Random(42);
  _ConfettiPainter(this.progress);

  static const _colors = [
    Color(0xFF7C5CBF), Color(0xFFFFD18C), Color(0xFF4CAF50),
    Color(0xFFFFB085), Color(0xFF2196F3), Color(0xFFE91E63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = (progress * speed * size.height * 1.3) % size.height;
      final color = _colors[i % _colors.length];
      final paint = Paint()..color = color.withOpacity(0.8);
      final w = 6.0 + rng.nextDouble() * 6;
      final h = 4.0 + rng.nextDouble() * 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
