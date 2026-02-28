import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  const ApplicationsListScreen({super.key});
  @override State<ApplicationsListScreen> createState() => _State();
}

class _State extends State<ApplicationsListScreen>
    with SingleTickerProviderStateMixin {
  final _api = AdminApiService();
  List<dynamic> _apps     = [];
  List<dynamic> _filtered = [];
  Map<String, dynamic>? _stats; // portfolio analytics
  bool          _loading  = true;
  String        _selected = 'ALL';

  static const _tabs = ['ALL', 'PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED'];

  @override void initState() { super.initState(); _loadApps(); }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AdminAuthProvider>().token!;
      final results = await Future.wait([
        _api.getApplications(token),
        _api.getPortfolioStats(token),
      ]);
      _apps  = results[0] as List;
      _stats = results[1] as Map<String, dynamic>?;
      _applyFilter();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kError));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() => setState(() {
    _filtered = _selected == 'ALL'
        ? _apps
        : _apps.where((a) => a['status'] == _selected).toList();
  });

  int _count(String s) => _apps.where((a) => a['status'] == s).length;

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = (v as num).toDouble();
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return '₹${(n / 1000).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Stats strip ───────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Loan Applications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextDark)),
            Row(children: [
              Text('${_filtered.length} shown',
                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
              const SizedBox(width: 12),
              _RefreshButton(onTap: _loadApps),
            ]),
          ]),
          const SizedBox(height: 16),

          // Stripe-style stat pills
          Row(children: [
            _StatPill(label: 'Total', value: _apps.length, color: kPrimary),
            const SizedBox(width: 10),
            _StatPill(label: 'Pending', value: _count('PENDING'), color: kWarning),
            const SizedBox(width: 10),
            _StatPill(label: 'Approved', value: _count('APPROVED'), color: kSuccess),
            const SizedBox(width: 10),
            _StatPill(label: 'Rejected', value: _count('REJECTED'), color: kError),
          ]),
          const SizedBox(height: 12),

          // ── Portfolio analytics row ───────────────────────────────
          if (_stats != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withOpacity(0.08)),
              ),
              child: Row(children: [
                _AnalyticsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Total Disbursed',
                    value: _fmt(_stats!['total_disbursed']),
                    color: kSuccess),
                _vDivider(),
                _AnalyticsTile(
                    icon: Icons.check_circle_rounded,
                    label: 'Approval Rate',
                    value: '${_stats!['approval_rate']}%',
                    color: kPrimary),
                _vDivider(),
                _AnalyticsTile(
                    icon: Icons.shield_rounded,
                    label: 'Avg Risk Score',
                    value: '${_stats!['avg_risk_score']}',
                    color: kWarning),
              ]),
            ),
          const SizedBox(height: 16),
        ]),
      ),

      // ── Tab filters ───────────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: Column(children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEECF5)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
            child: Row(children: _tabs.map((t) => _TabItem(
              label: t == 'UNDER_REVIEW' ? 'In Review' : t.capitalizeFirst(),
              selected: t == _selected,
              color: t == 'ALL' ? kPrimary : statusColor(t),
              onTap: () { _selected = t; _applyFilter(); },
            )).toList()),
          ),
        ]),
      ),

      // ── Table ─────────────────────────────────────────────────────────
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _filtered.isEmpty
                ? _EmptyState()
                : Container(
                    margin: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEECF5), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(children: [
                        // Header row
                        _TableHeader(),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEECF5)),
                        // Data rows
                        Expanded(child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF7F6FC)),
                          itemBuilder: (_, i) => _AppRow(
                            app: _filtered[i],
                            isEven: i % 2 == 0,
                            fmt: _fmt,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ApplicationDetailScreen(app: _filtered[i]),
                            )).then((_) => _loadApps()),
                          ),
                        )),
                      ]),
                    ),
                  ),
      ),
    ]),
  );
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
    ]),
  );
}

// ── Tab Item ──────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TabItem({required this.label, required this.selected, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
            color: selected ? color : Colors.transparent, width: 2)),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? color : kTextMuted)),
    ),
  );
}

// ── Table Header ──────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(
    color: const Color(0xFFFAF9FE),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    child: const Row(children: [
      Expanded(flex: 3, child: _HCol('Business')),
      Expanded(flex: 2, child: _HCol('Amount')),
      Expanded(flex: 1, child: _HCol('Tenure')),
      Expanded(flex: 2, child: _HCol('Purpose')),
      Expanded(flex: 2, child: _HCol('Risk Score')),
      Expanded(flex: 2, child: _HCol('Status')),
      Expanded(flex: 2, child: _HCol('Action')),
    ]),
  );
}

class _HCol extends StatelessWidget {
  final String label;
  const _HCol(this.label);
  @override Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: kTextMuted, letterSpacing: 0.5));
}

// ── App Row ───────────────────────────────────────────────────────────────────
class _AppRow extends StatefulWidget {
  final Map<String, dynamic> app;
  final bool isEven;
  final String Function(dynamic) fmt;
  final VoidCallback onTap;
  const _AppRow({required this.app, required this.isEven, required this.fmt, required this.onTap});
  @override State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _hovered = false;

  @override Widget build(BuildContext context) {
    final app    = widget.app;
    final status = (app['status'] ?? '') as String;
    final score  = (app['risk_score'] ?? 0) as int;
    final flags  = (app['risk_flags'] as List?)?.cast<String>() ?? <String>[];
    final business = app['business_name'] as String? ??
        (app['business_id'] as String? ?? '').substring(0, 8).toUpperCase();
    final purpose = (app['purpose'] ?? '').toString().replaceAll('_', ' ');

    final riskColor = score >= 70 ? kSuccess : score >= 45 ? kWarning : kError;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hovered
            ? kPrimary.withOpacity(0.04)
            : widget.isEven
                ? Colors.white
                : const Color(0xFFFCFBFE),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          // Business name
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(business, style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: kTextDark), overflow: TextOverflow.ellipsis),
            if (flags.isNotEmpty)
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 11, color: kWarning),
                const SizedBox(width: 3),
                Text('${flags.length} flag${flags.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 10, color: kWarning)),
              ]),
          ])),
          // Amount
          Expanded(flex: 2, child: Text(widget.fmt(app['requested_amount']),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                  color: kTextDark))),
          // Tenure
          Expanded(flex: 1, child: Text('${app['tenure_months']}m',
              style: const TextStyle(fontSize: 13, color: kTextMuted))),
          // Purpose
          Expanded(flex: 2, child: Text(purpose,
              style: const TextStyle(fontSize: 12, color: kTextMuted),
              overflow: TextOverflow.ellipsis)),
          // Risk score
          Expanded(flex: 2, child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('$score', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: riskColor)),
            const SizedBox(width: 4),
            Text(score >= 70 ? 'Low' : score >= 45 ? 'Med' : 'High',
                style: TextStyle(fontSize: 11, color: riskColor.withOpacity(0.7))),
          ])),
          // Status chip
          Expanded(flex: 2, child: _StatusBadge(status)),
          // Action
          Expanded(flex: 2, child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kPrimary.withOpacity(0.4), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Text('Review', style: TextStyle(fontSize: 12, color: kPrimary,
                    fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: kPrimary),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  @override Widget build(BuildContext context) {
    final color = statusColor(status);
    final label = status == 'UNDER_REVIEW' ? 'In Review' : status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), shape: BoxShape.circle),
      child: const Icon(Icons.inbox_rounded, size: 40, color: kPrimary),
    ),
    const SizedBox(height: 16),
    const Text('No applications found',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark)),
    const SizedBox(height: 6),
    const Text('Try a different filter or wait for new submissions',
        style: TextStyle(fontSize: 12, color: kTextMuted)),
  ]));
}

// ── Refresh Button ────────────────────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimary.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.refresh_rounded, size: 14, color: kPrimary),
        SizedBox(width: 5),
        Text('Refresh', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

extension _StrExt on String {
  String capitalizeFirst() => isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
}

// ── Analytics Tile ─────────────────────────────────────────────────────────────
class _AnalyticsTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _AnalyticsTile({required this.icon, required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ]),
  ));
}

Widget _vDivider() => Container(width: 1, height: 40, color: const Color(0xFFEEEEEE));
