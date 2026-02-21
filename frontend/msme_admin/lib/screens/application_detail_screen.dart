import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> app;
  const ApplicationDetailScreen({super.key, required this.app});
  @override State<ApplicationDetailScreen> createState() => _State();
}

class _State extends State<ApplicationDetailScreen> {
  final _api = AdminApiService();
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _expenseData;
  Map<String, dynamic>? _revenueData;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AdminAuthProvider>().token!;
    final appId = widget.app['app_id'];
    try {
      final results = await Future.wait([
        _api.getApplicationDetail(token, appId),
        _api.getExpenseChart(token, appId),
        _api.getRevenueChart(token, appId),
      ]);
      setState(() {
        _detail      = results[0];
        _expenseData = results[1];
        _revenueData = results[2];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _showDecisionDialog(String decision) async {
    final remarksCtrl = TextEditingController();
    final decisionColor = decision == 'APPROVED' ? kSuccess
        : decision == 'REJECTED' ? kError : kWarning;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(decision == 'APPROVED' ? Icons.check_circle
              : decision == 'REJECTED' ? Icons.cancel : Icons.info_outline,
              color: decisionColor),
          const SizedBox(width: 10),
          Text(decision.replaceAll('_', ' ')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Are you sure you want to mark this application as'
              ' ${decision.replaceAll("_", " ")}?'),
          const SizedBox(height: 16),
          TextField(
            controller: remarksCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Admin Remarks (optional)',
              hintText: 'e.g. Good credit profile. Approved.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: decisionColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final token = context.read<AdminAuthProvider>().token!;
        await _api.submitDecision(token, widget.app['app_id'], decision, remarksCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Application marked as ${decision.replaceAll("_", " ")}'),
                backgroundColor: decisionColor));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kError));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final status = app['status'] ?? '';
    final score = app['risk_score'] ?? 0;
    final flags = (app['risk_flags'] as List?)?.cast<String>() ?? [];
    final canDecide = status == 'PENDING' || status == 'UNDER_REVIEW';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text('Application — ${app['app_id'].toString().substring(0, 8).toUpperCase()}'),
        elevation: 0,
        actions: canDecide ? [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kSuccess),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              onPressed: () => _showDecisionDialog('APPROVED'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kError),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              onPressed: () => _showDecisionDialog('REJECTED'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kWarning),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('More Info'),
              onPressed: () => _showDecisionDialog('UNDER_REVIEW'),
            ),
          ),
        ] : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Left Column ───────────────────────────────────────────
                Expanded(flex: 3, child: Column(children: [
                  // Loan Summary Card
                  _Card(title: 'Loan Details', children: [
                    _InfoGrid([
                      _Info('Amount', '₹ ${_fmt(app['requested_amount'])}'),
                      _Info('Tenure', '${app['tenure_months']} months'),
                      _Info('Purpose', (app['purpose'] ?? '').toString().replaceAll('_', ' ')),
                      _Info('Status', status.replaceAll('_', ' ')),
                      _Info('Turnover', '₹ ${_fmt(app['declared_turnover'])}'),
                      _Info('Profit', '₹ ${_fmt(app['declared_profit'])}'),
                    ]),
                  ]),
                  const SizedBox(height: 20),

                  // Risk Score Card
                  _Card(title: 'Risk Assessment', children: [
                    Row(children: [
                      // Score Gauge
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: score >= 80 ? kSuccess.withOpacity(0.1)
                              : score >= 60 ? kWarning.withOpacity(0.1) : kError.withOpacity(0.1),
                          border: Border.all(
                            color: score >= 80 ? kSuccess : score >= 60 ? kWarning : kError,
                            width: 3,
                          ),
                        ),
                        child: Center(child: Text('$score',
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800,
                              color: score >= 80 ? kSuccess : score >= 60 ? kWarning : kError,
                            ))),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(score >= 80 ? 'Low Risk' : score >= 60 ? 'Medium Risk' : 'High Risk',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: score >= 80 ? kSuccess : score >= 60 ? kWarning : kError)),
                        const SizedBox(height: 4),
                        Text('out of 100 — higher is better',
                            style: const TextStyle(fontSize: 12, color: kTextMuted)),
                        if (flags.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Row(children: [Icon(Icons.check_circle, color: kSuccess, size: 14),
                            SizedBox(width: 4), Text('No risk flags', style: TextStyle(fontSize: 12, color: kSuccess))]),
                        ],
                      ])),
                    ]),
                    if (flags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 6, children: flags.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: kError.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kError.withOpacity(0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.warning_amber, size: 12, color: kError),
                          const SizedBox(width: 4),
                          Text(f.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 11, color: kError, fontWeight: FontWeight.w600)),
                        ]),
                      )).toList()),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Admin Remarks
                  if (app['admin_remarks'] != null)
                    _Card(title: 'Admin Remarks', children: [
                      Text(app['admin_remarks'] ?? '',
                          style: const TextStyle(color: kTextDark, height: 1.5)),
                    ]),
                ])),

                const SizedBox(width: 20),

                // ── Right Column — Charts ─────────────────────────────────
                Expanded(flex: 4, child: Column(children: [
                  // Revenue Line Chart
                  if (_revenueData != null)
                    _Card(title: '📈 Revenue Trend (6 Months)', children: [
                      SizedBox(height: 200, child: _RevenueChart(_revenueData!)),
                    ]),
                  const SizedBox(height: 20),

                  // Expense Pie Chart
                  if (_expenseData != null)
                    _Card(title: '🥧 Expense Breakdown', children: [
                      SizedBox(height: 200, child: _ExpensePieChart(_expenseData!)),
                    ]),
                ])),
              ]),
            ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = (v as num).toDouble();
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return '${(n / 1000).toStringAsFixed(0)}K';
  }
}

// ── Charts ────────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RevenueChart(this.data);

  @override
  Widget build(BuildContext context) {
    final months = (data['months'] as List?)?.cast<String>() ?? [];
    final values = (data['revenue'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            return i >= 0 && i < months.length
                ? Text(months[i], style: const TextStyle(fontSize: 10, color: kTextMuted))
                : const SizedBox();
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        color: kPrimary,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: kPrimary.withOpacity(0.08)),
      )],
    ));
  }
}

class _ExpensePieChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExpensePieChart(this.data);

  static const _colors = [kPrimary, kAccent, kSuccess, kWarning, kError, Color(0xFF26C6DA)];

  @override
  Widget build(BuildContext context) {
    final categories = (data['categories'] as List?)?.cast<String>() ?? [];
    final values = (data['values'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));

    return Row(children: [
      Expanded(
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 35,
          sections: values.asMap().entries.map((e) => PieChartSectionData(
            color: _colors[e.key % _colors.length],
            value: e.value,
            title: '',
            radius: 60,
          )).toList(),
        )),
      ),
      const SizedBox(width: 16),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _colors[e.key % _colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(e.value, style: const TextStyle(fontSize: 11, color: kTextDark)),
          ]),
        )).toList(),
      ),
    ]);
  }
}

// ── Layout Helpers ─────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}

class _InfoGrid extends StatelessWidget {
  final List<_Info> items;
  const _InfoGrid(this.items);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16, runSpacing: 12,
    children: items.map((i) => SizedBox(width: 160, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i.label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
          const SizedBox(height: 2),
          Text(i.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark)),
        ]))).toList(),
  );
}

class _Info {
  final String label, value;
  const _Info(this.label, this.value);
}
