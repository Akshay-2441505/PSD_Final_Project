import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import 'loan_apply_screen.dart';
import 'loan_status_screen.dart';
import '../screens/login_screen.dart';
import 'financial_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _insights;
  List<dynamic> _loans = [];
  bool _loading = true;

  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token!;
    try {
      final ins = await _api.getDashboardInsights(token);
      final loans = await _api.getMyLoans(token);
      if (mounted) {
        setState(() { _insights = ins; _loans = loans; _loading = false; });
        _heroCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?['legal_name'] as String? ?? 'there';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: kBackground,
      // Floating Apply Button - Modern approach
      floatingActionButton: !_loading ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoanApplyScreen()),
        ).then((_) => _load()),
        backgroundColor: kAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Apply Loan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ) : null,
      body: SafeArea(
        child: Stack(children: [
          // ── Content ──────────────────────────────────────────────────
          _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: CustomScrollView(
                    slivers: [
                      // ── Hero Header ───────────────────────────────────
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _heroFade,
                          child: _HeroHeader(
                            greeting: _greeting(),
                            firstName: firstName,
                            insights: _insights,
                            onRefresh: _load,
                            onLogout: () async {
                              await auth.logout();
                              if (!mounted) return;
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()));
                            },
                          ),
                        ),
                      ),

                      // ── Quick Stats ───────────────────────────────────
                      if (_insights != null)
                        SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _heroFade,
                            child: _QuickStats(insights: _insights!),
                          ),
                        ),

                      // ── Section: My Applications ──────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('My Applications',
                                  style: kHeading2(context).copyWith(color: kTextDark)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${_loans.length} total',
                                    style: const TextStyle(
                                        color: kPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                        ),
                      ),

                      // ── Loan Cards ────────────────────────────────────
                      if (_loans.isEmpty)
                        SliverToBoxAdapter(child: _EmptyState().animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.95))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _LoanCard(
                              loan: _loans[i],
                              index: i,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LoanStatusScreen(
                                        loanId: _loans[i]['app_id'])),
                              ).then((_) => _load()),
                            ).animate(delay: (i * 100).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                            childCount: _loans.length,
                          ),
                        ),

                      // ── Charts ────────────────────────────────────────
                      if (_insights != null) ...[ 
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Revenue Trend',
                                    style: kHeading2(context).copyWith(color: kTextDark)),
                                GestureDetector(
                                  onTap: () async {
                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const FinancialSetupScreen(),
                                      ),
                                    );
                                    if (updated == true) _load();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    child: const Row(children: [
                                      Icon(Icons.edit_note_rounded, size: 16, color: kPrimary),
                                      SizedBox(width: 6),
                                      Text('Update Data',
                                          style: TextStyle(
                                              color: kPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _RevenueChart(
                                data: _insights!['monthly_revenue'] as List).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.95),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                            child: Text('Expense Breakdown',
                                style: kHeading2(context).copyWith(color: kTextDark))
                            .animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _ExpensePieChart(
                                data: _insights!['expense_breakdown'] as List).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.95),
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                ),
        ]),
      ),
    );
  }
}

// ── Hero Header ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String firstName;
  final Map<String, dynamic>? insights;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  const _HeroHeader({
    required this.greeting,
    required this.firstName,
    required this.insights,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final approved = (insights?['approved_amount'] ?? 0.0) as num;
    final health   = insights?['health_score'] ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 18,
                child: Icon(Icons.business, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          Row(children: [
            _IconBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
            const SizedBox(width: 8),
            _IconBtn(icon: Icons.logout_rounded, onTap: onLogout),
          ]),
        ]),
        const SizedBox(height: 32),

        // Amount
        const Text('Total Loan Approved', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        _AnimatedAmount(target: approved.toDouble()),
        const SizedBox(height: 20),

        // Health badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccent.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.insights_rounded, color: kAccent, size: 16),
            const SizedBox(width: 8),
            Text('Business Health Score: $health%',
                style: const TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

// Animated number counter
class _AnimatedAmount extends StatefulWidget {
  final double target;
  const _AnimatedAmount({required this.target});
  @override State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(double v) => v >= 100000
      ? '₹ ${(v / 100000).toStringAsFixed(2)}L'
      : '₹ ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Text(
          _fmt(widget.target * _anim.value),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1),
        ),
      );
}

// ── Quick Stats ──────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final Map<String, dynamic> insights;
  const _QuickStats({required this.insights});

  @override
  Widget build(BuildContext context) {
    final pending = insights['pending_count'] ?? 0;
    final emi     = insights['next_emi_due'] ?? 'N/A';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _Stat(icon: Icons.pending_actions_rounded, label: 'Pending Loans', value: '$pending', color: kWarning),
          _Divider(),
          _Stat(icon: Icons.calendar_month_rounded, label: 'Next EMI Date', value: emi, color: kPrimary),
          _Divider(),
          _Stat(icon: Icons.verified_rounded, label: 'Account Status', value: 'Active', color: kSuccess),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: const Color(0xFFEEEEEE));
}

// ── Loan Card ────────────────────────────────────────────────────────────────
class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onTap;
  final int index;
  const _LoanCard({required this.loan, required this.onTap, required this.index});

  Color _statusColor(String s) => switch (s) {
    'APPROVED'     => kSuccess,
    'REJECTED'     => kError,
    'PENDING'      => kWarning,
    'UNDER_REVIEW' => const Color(0xFF2196F3),
    _              => kTextMuted,
  };

  IconData _statusIcon(String s) => switch (s) {
    'APPROVED'     => Icons.check_circle_rounded,
    'REJECTED'     => Icons.cancel_rounded,
    'PENDING'      => Icons.schedule_rounded,
    'UNDER_REVIEW' => Icons.manage_search_rounded,
    _              => Icons.circle_outlined,
  };

  String _fmtAmount(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    return n >= 100000 ? '₹${(n / 100000).toStringAsFixed(1)}L' : '₹${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] as String;
    final color  = _statusColor(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Colored left strip
          Container(
            width: 6, height: 80,
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16))),
          ),
          const SizedBox(width: 16),
          // Status icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_statusIcon(status), color: color, size: 22),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(_fmtAmount(loan['requested_amount']),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 4),
            Text('${loan['tenure_months']} months • ${(loan['purpose'] as String).replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 13, color: kTextMuted)),
          ])),
          // Status badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2))),
            child: Text(status.replaceAll('_', ' '),
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: kCardGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.receipt_long_rounded, size: 36, color: Colors.white),
      ),
      const SizedBox(height: 16),
      const Text('No applications yet',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextDark)),
      const SizedBox(height: 6),
      const Text('Tap the button below to apply for your first loan',
          style: TextStyle(fontSize: 12, color: kTextMuted), textAlign: TextAlign.center),
    ]),
  );
}

// ── Revenue Chart ─────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List data;
  const _RevenueChart({required this.data});

  /// Abbreviate "Oct 2025" → "Oct '25"
  static String _abbr(String month) {
    final p = month.split(' ');
    if (p.length < 2) return month;
    final yr = p[1];
    return "${p[0]} '${yr.length >= 4 ? yr.substring(2) : yr}";
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    // Use num cast — JSONB can return double or int depending on stored value
    final values = data
        .map((e) => (e['revenue'] as num).toDouble() / 1000)
        .toList();
    final spots = values.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14)],
      ),
      child: LineChart(LineChartData(
        minY: 0,
        maxY: (maxY * 1.35).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0xFFF0EEF8), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),

        // ── Tooltip: dark bg + white text for good contrast ───────────
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2D2549),
            getTooltipItems: (touched) => touched.map((s) => LineTooltipItem(
              '₹${s.y.toStringAsFixed(1)}K',
              const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            )).toList(),
          ),
        ),

        titlesData: FlTitlesData(
          // ── Bottom: only at integer x positions, abbreviated labels ──
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1, // suppresses half-tick duplicates
            getTitlesWidget: (v, meta) {
              // Skip non-integer positions that fl_chart sometimes emits
              if ((v - v.roundToDouble()).abs() > 0.01) return const SizedBox();
              final i = v.round();
              if (i < 0 || i >= data.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _abbr(data[i]['month'] as String? ?? ''),
                  style: const TextStyle(fontSize: 9, color: kTextMuted),
                ),
              );
            },
          )),
          // ── Left: ₹K values with breathing room ──────────────────────
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (v, meta) {
              if (v == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('₹${v.toInt()}K',
                    style: const TextStyle(fontSize: 9, color: kTextMuted)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots,
          isCurved: true,
          color: kPrimary,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4, color: kPrimary, strokeWidth: 2, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.18), kPrimary.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        )],
      )),
    );
  }
}

// ── Expense Pie ───────────────────────────────────────────────────────────────
class _ExpensePieChart extends StatelessWidget {
  final List data;
  const _ExpensePieChart({required this.data});

  static const _colors = [
    kPrimary, Color(0xFFFFB085), Color(0xFFFFD18C),
    kPrimaryLight, Color(0xFF80CBC4), Color(0xFFEF9A9A), Color(0xFF81C784),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14)],
      ),
      child: Row(children: [
        SizedBox(
          height: 140, width: 140,
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 32,
            sections: data.asMap().entries.map((e) => PieChartSectionData(
              value: (e.value['percentage'] as num).toDouble(), // JSONB may give double
              color: _colors[e.key % _colors.length],
              radius: 52,
              showTitle: false,
            )).toList(),
          )),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: _colors[e.key % _colors.length],
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value['category'],
                  style: const TextStyle(fontSize: 11, color: kTextDark))),
              Text('${(e.value['percentage'] as num).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: kTextMuted,
                      fontWeight: FontWeight.w600)),
            ]),
          )).toList(),
        )),
      ]),
    );
  }
}
