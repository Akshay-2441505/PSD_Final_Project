import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});
  @override State<ChartsScreen> createState() => _State();
}

class _State extends State<ChartsScreen> {
  final _api = AdminApiService();
  List<dynamic> _apps = [];
  Map<String, dynamic>? _expense;
  Map<String, dynamic>? _revenue;
  bool _loading = true;
  String? _selectedAppId;

  @override
  void initState() { super.initState(); _loadApps(); }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    final token = context.read<AdminAuthProvider>().token!;
    try {
      _apps = await _api.getApplications(token);
      if (_apps.isNotEmpty) {
        _selectedAppId = _apps.first['app_id'];
        await _loadCharts(token, _selectedAppId!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCharts(String token, String appId) async {
    try {
      final results = await Future.wait([
        _api.getExpenseChart(token, appId),
        _api.getRevenueChart(token, appId),
      ]);
      setState(() { _expense = results[0]; _revenue = results[1]; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          const Text('Business Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Simulated financial charts from Account Aggregator data',
              style: TextStyle(color: kTextMuted, fontSize: 13)),
          const SizedBox(height: 20),

          // Application Selector
          Row(children: [
            const Text('Viewing Application: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            if (_apps.isNotEmpty)
              DropdownButton<String>(
                value: _selectedAppId,
                underline: const SizedBox(),
                items: _apps.map<DropdownMenuItem<String>>((a) => DropdownMenuItem(
                  value: a['app_id'] as String,
                  child: Text(
                    '${a['app_id'].toString().substring(0, 8).toUpperCase()}  •  ₹ ${_fmt(a['requested_amount'])}  •  ${a['status']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                )).toList(),
                onChanged: (id) async {
                  setState(() { _selectedAppId = id; _expense = null; _revenue = null; });
                  final token = context.read<AdminAuthProvider>().token!;
                  await _loadCharts(token, id!);
                },
              ),
          ]),
          const SizedBox(height: 24),

          // Charts
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Revenue Line Chart
              Expanded(child: _ChartCard(
                title: '📈 Monthly Revenue Trend',
                subtitle: '6-month Account Aggregator data',
                child: _revenue == null
                    ? const Center(child: Text('No data'))
                    : _RevenueLineChart(_revenue!),
              )),
              const SizedBox(width: 20),

              // Expense Pie Chart
              Expanded(child: _ChartCard(
                title: '🥧 Expense Breakdown',
                subtitle: 'Category-wise spending analysis',
                child: _expense == null
                    ? const Center(child: Text('No data'))
                    : _ExpensePieChart(_expense!),
              )),
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

class _RevenueLineChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RevenueLineChart(this.data);

  @override
  Widget build(BuildContext context) {
    final months = (data['months'] as List?)?.cast<String>() ?? [];
    final values = (data['revenue'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 50,
          getTitlesWidget: (v, _) => Text('₹${(v / 1000).toStringAsFixed(0)}K',
              style: const TextStyle(fontSize: 9, color: kTextMuted)),
        )),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 30,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            return i >= 0 && i < months.length
                ? Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(months[i], style: const TextStyle(fontSize: 10, color: kTextMuted)))
                : const SizedBox();
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true, color: kPrimary, barWidth: 3,
        dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 4, color: kPrimary, strokeWidth: 2, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true, color: kPrimary.withOpacity(0.07)),
      )],
    ));
  }
}

class _ExpensePieChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExpensePieChart(this.data);

  static const _colors = [kPrimary, Color(0xFFFF7043), kSuccess, kAccent, kWarning, Color(0xFF26C6DA)];

  @override
  Widget build(BuildContext context) {
    final categories = (data['categories'] as List?)?.cast<String>() ?? [];
    final values = (data['values'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));
    final total = values.fold(0.0, (a, b) => a + b);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 180, height: 180,
        child: PieChart(PieChartData(
          sectionsSpace: 3, centerSpaceRadius: 45,
          sections: values.asMap().entries.map((e) => PieChartSectionData(
            color: _colors[e.key % _colors.length],
            value: e.value,
            title: '${(e.value / total * 100).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            radius: 60,
          )).toList(),
        )),
      ),
      const SizedBox(width: 20),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Container(width: 12, height: 12,
                decoration: BoxDecoration(color: _colors[e.key % _colors.length], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(e.value, style: const TextStyle(fontSize: 12, color: kTextDark)),
            const SizedBox(width: 8),
            Text('₹${(values[e.key] / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(fontSize: 11, color: kTextMuted)),
          ]),
        )).toList(),
      ),
    ]);
  }
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kSurface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextMuted)),
      const SizedBox(height: 20),
      SizedBox(height: 260, child: child),
    ]),
  );
}
