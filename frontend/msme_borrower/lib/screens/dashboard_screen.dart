import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import 'loan_apply_screen.dart';
import 'loan_status_screen.dart';
import '../screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api   = ApiService();
  Map<String, dynamic>? _insights;
  List<dynamic>  _loans   = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    try {
      final ins   = await _api.getDashboardInsights(token);
      final loans = await _api.getMyLoans(token);
      if (mounted) setState(() { _insights = ins; _loans = loans; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanApplyScreen()))
            .then((_) => _load()),
        backgroundColor: kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply for Loan', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                // ── Hero Card ─────────────────────────────────────────
                _HeroCard(insights: _insights),
                const SizedBox(height: 20),

                // ── Loan Applications ─────────────────────────────────
                Text('My Applications', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: kTextDark)),
                const SizedBox(height: 12),
                if (_loans.isEmpty)
                  _EmptyState()
                else
                  ..._loans.map((l) => _LoanCard(loan: l,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LoanStatusScreen(loanId: l['app_id']))))),

                const SizedBox(height: 20),
                // ── Financial Insights ────────────────────────────────
                if (_insights != null) ...[
                  Text('Revenue Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: kTextDark)),
                  const SizedBox(height: 12),
                  _RevenueChart(data: _insights!['monthly_revenue'] as List),
                  const SizedBox(height: 20),
                  Text('Expense Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: kTextDark)),
                  const SizedBox(height: 12),
                  _ExpensePieChart(data: _insights!['expense_breakdown'] as List),
                ],
                const SizedBox(height: 100),
              ]),
            ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final Map<String, dynamic>? insights;
  const _HeroCard({this.insights});

  @override
  Widget build(BuildContext context) {
    final approved = insights?['approved_amount'] ?? 0.0;
    final health   = insights?['health_score'] ?? 0;
    final pending  = insights?['pending_count'] ?? 0;
    final emi      = insights?['next_emi_due'] ?? 'N/A';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: kHeroGradient, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Approved Loan', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text('Health $health%', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('₹ ${_fmt(approved.toDouble())}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          _InfoChip(Icons.pending_actions, '$pending Pending'),
          const SizedBox(width: 12),
          _InfoChip(Icons.calendar_today, 'EMI: $emi'),
        ]),
      ]),
    );
  }

  String _fmt(double v) => v >= 100000
      ? '${(v / 100000).toStringAsFixed(1)}L'
      : v.toStringAsFixed(0);
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip(this.icon, this.label);
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Colors.white70, size: 14),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);
}

// ── Loan Card ─────────────────────────────────────────────────────────────
class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onTap;
  const _LoanCard({required this.loan, required this.onTap});

  Color _statusColor(String s) => switch (s) {
    'APPROVED'           => kSuccess,
    'REJECTED'           => kError,
    'PENDING'            => kWarning,
    'UNDER_REVIEW'       => Colors.blue,
    _                    => kTextMuted,
  };

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] as String;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 4, height: 48, decoration: BoxDecoration(
              color: _statusColor(status), borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('₹ ${loan['requested_amount']}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kTextDark)),
            const SizedBox(height: 2),
            Text('${loan['tenure_months']} months • ${(loan['purpose'] as String).replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 12, color: kTextMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' '),
                style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: kTextMuted),
        ]),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    alignment: Alignment.center,
    child: Column(children: [
      Icon(Icons.receipt_long, size: 56, color: kPrimaryLight),
      const SizedBox(height: 12),
      Text('No loan applications yet', style: TextStyle(color: kTextMuted)),
      Text('Tap + to apply for your first loan', style: TextStyle(color: kTextMuted, fontSize: 12)),
    ]),
  );
}

// ── Revenue Line Chart ────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value['revenue'] as int) / 1000)).toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
              getTitlesWidget: (v, _) => Text(data[v.toInt()]['month'], style: const TextStyle(fontSize: 10, color: kTextMuted)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, color: kPrimary, barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: kPrimary.withOpacity(0.12)),
        )],
      )),
    );
  }
}

// ── Expense Pie Chart ─────────────────────────────────────────────────────
class _ExpensePieChart extends StatelessWidget {
  final List data;
  const _ExpensePieChart({required this.data});

  static const _colors = [kPrimary, kAccent, kAccentPeach, kPrimaryLight, Color(0xFF80CBC4), Color(0xFFEF9A9A)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        SizedBox(height: 140, width: 140,
          child: PieChart(PieChartData(
            sectionsSpace: 2, centerSpaceRadius: 30,
            sections: data.asMap().entries.map((e) => PieChartSectionData(
              value: (e.value['percentage'] as int).toDouble(),
              color: _colors[e.key % _colors.length],
              radius: 50, showTitle: false,
            )).toList(),
          )),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: data.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: _colors[e.key % _colors.length], shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(e.value['category'],
                  style: const TextStyle(fontSize: 11, color: kTextDark))),
              Text('${e.value['percentage']}%', style: const TextStyle(fontSize: 11, color: kTextMuted)),
            ]),
          )).toList(),
        )),
      ]),
    );
  }
}
