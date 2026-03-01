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
  final _api         = AdminApiService();
  final _remarksCtrl = TextEditingController();
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _expenseData;
  Map<String, dynamic>? _revenueData;
  bool _loading        = true;
  bool _submitting     = false;

  @override void initState() { super.initState(); _load(); }

  @override void dispose() { _remarksCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final token = context.read<AdminAuthProvider>().token!;
    final appId = widget.app['app_id'];
    try {
      final results = await Future.wait([
        _api.getApplicationDetail(token, appId),
        _api.getExpenseChart(token, appId),
        _api.getRevenueChart(token, appId),
      ]);
      if (mounted) setState(() {
        _detail      = results[0];
        _expenseData = results[1];
        _revenueData = results[2];
        _loading     = false;
        // Pre-fill remarks if already set
        _remarksCtrl.text = results[0]['admin_remarks'] ?? '';
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _submitDecision(String decision) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final token = context.read<AdminAuthProvider>().token!;
      await _api.submitDecision(token, widget.app['app_id'], decision, _remarksCtrl.text);
      if (mounted) {
        final color = decision == 'APPROVED' ? kSuccess
            : decision == 'REJECTED' ? kError : kWarning;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Marked as ${decision.replaceAll('_', ' ')}'),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app      = widget.app;
    final status   = (app['status'] ?? '') as String;
    final score    = (app['risk_score'] ?? 0) as int;
    final flags    = (app['risk_flags'] as List?)?.cast<String>() ?? <String>[];
    final canDecide = status == 'PENDING' || status == 'UNDER_REVIEW';
    final business  = app['business_name'] as String? ??
        (app['business_id'] as String? ?? '').substring(0, 8).toUpperCase();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEECF5)),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: kTextDark),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Application — ${app['app_id'].toString().substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(business, style: const TextStyle(fontSize: 11, color: kTextMuted,
              fontWeight: FontWeight.w400)),
        ]),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEECF5)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Left scrollable column ─────────────────────────────────
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    // Borrower profile card
                    _ProfileCard(app: app, business: business),
                    const SizedBox(height: 20),

                    // Loan details
                    _SectionCard(title: 'Loan Details', children: [
                      _InfoGrid([
                        _Info('Amount', '₹${_fmt(app['requested_amount'])}'),
                        _Info('Tenure', '${app['tenure_months']} months'),
                        _Info('Purpose', (app['purpose'] ?? '').toString().replaceAll('_', ' ')),
                        _Info('Turnover', '₹${_fmt(app['declared_turnover'])}'),
                        _Info('Profit',   '₹${_fmt(app['declared_profit'])}'),
                        _Info('Status',   status.replaceAll('_', ' ')),
                      ]),
                    ]),
                    const SizedBox(height: 20),

                    // Risk assessment with score breakdown
                    _RiskCard(
                      score: score,
                      flags: flags,
                      breakdown: (_detail?['score_breakdown'] as List?)?.cast<Map<String,dynamic>>() ?? const [],
                    ),

                    // Admin remarks (read-only, if already set and can't decide)
                    if (!canDecide && (app['admin_remarks'] as String? ?? '').isNotEmpty) ...[ 
                      const SizedBox(height: 20),
                      _SectionCard(title: 'Admin Remarks', children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(app['admin_remarks'],
                              style: const TextStyle(color: kTextDark, height: 1.5, fontSize: 13)),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),

              // ── Right sticky decision + charts panel ────────────────────
              Container(
                width: 1,
                color: const Color(0xFFEEECF5),
              ),
              Expanded(
                flex: 4,
                child: Column(children: [
                  // Decision panel — sticky at top
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Decision',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
                      const SizedBox(height: 12),

                      // Status badge
                      _StatusBadge(status),
                      const SizedBox(height: 16),

                      if (canDecide) ...[ 
                        // Inline remarks field
                        TextField(
                          controller: _remarksCtrl,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Remarks (optional)',
                            hintText: 'e.g. Good credit profile…',
                            filled: true,
                            fillColor: kBackground,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDDDAEE)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDDDAEE)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: kPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Decision buttons — inline, no dialog
                        if (_submitting)
                          const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(color: kPrimary),
                          ))
                        else ...[
                          _DecisionBtn(
                            label: 'Approve',
                            icon: Icons.check_circle_rounded,
                            color: kSuccess,
                            onTap: () => _confirmAndSubmit('APPROVED'),
                          ),
                          const SizedBox(height: 8),
                          _DecisionBtn(
                            label: 'Request More Info',
                            icon: Icons.help_outline_rounded,
                            color: kWarning,
                            onTap: () => _confirmAndSubmit('MORE_INFO_REQUESTED'),
                          ),
                          const SizedBox(height: 8),
                          _DecisionBtn(
                            label: 'Reject',
                            icon: Icons.cancel_rounded,
                            color: kError,
                            outline: true,
                            onTap: () => _confirmAndSubmit('REJECTED'),
                          ),
                        ],
                      ] else ...[ 
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEEECF5)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: kTextMuted),
                            SizedBox(width: 8),
                            Expanded(child: Text('Decision already made. No further action needed.',
                                style: TextStyle(fontSize: 12, color: kTextMuted))),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEECF5)),

                  // Charts — scroll inside right column
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        if (_revenueData != null) ...[ 
                          const Text('Revenue Trend',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
                          const SizedBox(height: 12),
                          SizedBox(height: 180, child: _RevenueChart(_revenueData!)),
                          const SizedBox(height: 20),
                        ],
                        if (_expenseData != null) ...[ 
                          const Text('Expense Breakdown',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
                          const SizedBox(height: 12),
                          SizedBox(height: 200, child: _ExpensePieChart(_expenseData!)),
                        ],
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }

  void _confirmAndSubmit(String decision) {
    final color = decision == 'APPROVED' ? kSuccess
        : decision == 'REJECTED' ? kError : kWarning;
    final icon  = decision == 'APPROVED' ? Icons.check_circle_rounded
        : decision == 'REJECTED' ? Icons.cancel_rounded : Icons.help_outline_rounded;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text('Confirm: ${decision.replaceAll('_', ' ')}',
              style: const TextStyle(fontSize: 16)),
        ]),
        content: Text(
          'This will mark the application as ${decision.replaceAll("_", " ")}.\n'
          'This action will notify the borrower.',
          style: const TextStyle(fontSize: 13, color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () { Navigator.pop(ctx, true); _submitDecision(decision); },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
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

// ── Decision Button ───────────────────────────────────────────────────────────
class _DecisionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outline;
  final VoidCallback onTap;
  const _DecisionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap, this.outline = false,
  });
  @override Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 42,
    child: outline
        ? OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(icon, size: 16),
            label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(icon, size: 16, color: Colors.white),
            label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
  );
}

// ── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final String business;
  const _ProfileCard({required this.app, required this.business});
  @override Widget build(BuildContext context) {
    final id = (app['app_id'] as String? ?? '');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1730), Color(0xFF3D2F72)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(
            business.isNotEmpty ? business[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(business, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('ID: ${id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ])),
      ]),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  @override Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(status.replaceAll('_', ' '),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ── Risk Card ─────────────────────────────────────────────────────────────────
class _RiskCard extends StatelessWidget {
  final int score;
  final List<String> flags;
  final List<Map<String, dynamic>> breakdown;
  const _RiskCard({required this.score, required this.flags, this.breakdown = const []});

  @override Widget build(BuildContext context) {
    final color = score >= 70 ? kSuccess : score >= 45 ? kWarning : kError;
    final label = score >= 70 ? 'Low Risk' : score >= 45 ? 'Moderate Risk' : 'High Risk';
    return _SectionCard(title: 'Risk Assessment', children: [
      // Score gauge row
      Row(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.08),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(child: Text('$score',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          const Text('out of 100 — higher is better',
              style: TextStyle(fontSize: 11, color: kTextMuted)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(height: 6, child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            )),
          ),
        ])),
      ]),

      // Score breakdown table
      if (breakdown.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFEEECF5)),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(flex: 3, child: Text('Rule', style: TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w600))),
          SizedBox(width: 8),
          Text('Impact', style: TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ...breakdown.map((item) {
          final impact     = (item['impact'] as num? ?? 0).toInt();
          final rule       = item['rule'] as String? ?? '';
          final detail     = item['detail'] as String? ?? '';
          final severity   = item['severity'] as String? ?? 'ok';
          final impactColor = impact < 0 ? kError : kSuccess;
          final bgColor    = severity == 'high'
              ? kError.withOpacity(0.04)
              : severity == 'medium'
              ? kWarning.withOpacity(0.04)
              : kSuccess.withOpacity(0.04);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: severity == 'high' ? kError.withOpacity(0.15)
                    : severity == 'medium' ? kWarning.withOpacity(0.15)
                    : kSuccess.withOpacity(0.15),
              ),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                impact < 0 ? Icons.remove_circle_outline : Icons.check_circle_outline,
                size: 14,
                color: impactColor,
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(rule, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: impactColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      impact == 0 ? '+0' : '$impact pts',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: impactColor),
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(fontSize: 11, color: kTextMuted, height: 1.4)),
              ])),
            ]),
          );
        }).toList(),
      ] else if (flags.isEmpty) ...[
        const SizedBox(height: 10),
        const Row(children: [
          Icon(Icons.check_circle_rounded, color: kSuccess, size: 13),
          SizedBox(width: 4),
          Text('No risk flags detected', style: TextStyle(fontSize: 11, color: kSuccess)),
        ]),
      ],
    ]);
  }
}

// ── Charts ────────────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RevenueChart(this.data);
  @override Widget build(BuildContext context) {
    final months = (data['months'] as List?)?.cast<String>() ?? [];
    final values = (data['revenue'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));
    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFF0EEF8), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 24,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            return i >= 0 && i < months.length
                ? Text(months[i], style: const TextStyle(fontSize: 9, color: kTextMuted))
                : const SizedBox();
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value / 1000)).toList(),
        isCurved: true, color: kPrimary, barWidth: 2.5,
        dotData: FlDotData(show: true,
            getDotPainter: (_, __, ___, ____) =>
                FlDotCirclePainter(radius: 3.5, color: kPrimary, strokeWidth: 2, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true,
            gradient: LinearGradient(colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
    ));
  }
}

class _ExpensePieChart extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExpensePieChart(this.data);
  static const _colors = [kPrimary, kAccent, kSuccess, kWarning, kError,
    Color(0xFF26C6DA), Color(0xFFAB47BC)];
  @override Widget build(BuildContext context) {
    final categories = (data['categories'] as List?)?.cast<String>() ?? [];
    final values     = (data['values'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    if (values.isEmpty) return const Center(child: Text('No data'));
    return Row(children: [
      Expanded(child: PieChart(PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 30,
        sections: values.asMap().entries.map((e) => PieChartSectionData(
          color: _colors[e.key % _colors.length],
          value: e.value, title: '', radius: 55,
        )).toList(),
      ))),
      const SizedBox(width: 12),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: _colors[e.key % _colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(e.value, style: const TextStyle(fontSize: 11, color: kTextDark)),
          ]),
        )).toList()),
    ]);
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}

// ── Info Grid ─────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final List<_Info> items;
  const _InfoGrid(this.items);
  @override Widget build(BuildContext context) => Wrap(
    spacing: 14, runSpacing: 12,
    children: items.map((i) => SizedBox(width: 150,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(i.label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
        const SizedBox(height: 3),
        Text(i.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark)),
      ]))).toList(),
  );
}

class _Info { final String label, value; const _Info(this.label, this.value); }
