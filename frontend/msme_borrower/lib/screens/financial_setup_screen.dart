import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';

/// Financial Setup / Update screen.
/// Allows borrowers to enter 6 months of revenue data and expense breakdown.
/// Can be accessed:
///   1. Right after registration (via push, then pop to Dashboard)
///   2. From the Dashboard "Update Financials" button
class FinancialSetupScreen extends StatefulWidget {
  final bool isPostRegistration; // if true, show "Skip for now" option
  const FinancialSetupScreen({super.key, this.isPostRegistration = false});
  @override State<FinancialSetupScreen> createState() => _FinancialSetupScreenState();
}

class _FinancialSetupScreenState extends State<FinancialSetupScreen> {
  final _api = ApiService();
  bool _loading = false;
  bool _prefilling = true;

  // ── 6 months of revenue entries ──────────────────────────────────────────
  final List<String> _monthLabels = _lastSixMonths();
  late final List<TextEditingController> _revenueCtrlList;

  // ── Expense breakdown (sliders) — 6 categories ─────────────────────────
  final List<String> _expenseCategories = [
    'Raw Materials', 'Salaries', 'Rent', 'Utilities', 'Logistics', 'Marketing',
  ];
  late List<double> _expensePercents;

  static List<String> _lastSixMonths() {
    final now = DateTime.now();
    const monthNames = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      months.add('${monthNames[(dt.month - 1) % 12]} ${dt.year}');
    }
    return months;
  }

  @override
  void initState() {
    super.initState();
    _revenueCtrlList = List.generate(6, (_) => TextEditingController());
    _expensePercents = [35.0, 25.0, 15.0, 8.0, 10.0, 7.0]; // default percentages
    _loadExisting();
  }

  @override
  void dispose() {
    for (final c in _revenueCtrlList) c.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final data = await _api.getMyFinancials(token);
      if (!mounted) return;
      if (data != null) {
        final revenues = (data['monthly_revenue'] as List?) ?? [];
        final expenses = (data['expense_breakdown'] as List?) ?? [];
        setState(() {
          for (int i = 0; i < revenues.length && i < 6; i++) {
            _revenueCtrlList[i].text = revenues[i]['revenue'].toString();
          }
          for (int i = 0; i < expenses.length && i < 6; i++) {
            _expensePercents[i] = (expenses[i]['percentage'] as num).toDouble();
          }
        });
      } else {
        // Pre-fill revenue from annual_turnover / 12 as a hint
        final profile = await _api.getMyProfile(token);
        if (!mounted) return;
        final turnover = (profile['annual_turnover'] as num?)?.toDouble();
        if (turnover != null && turnover > 0) {
          final monthly = (turnover / 12).round();
          for (final ctrl in _revenueCtrlList) {
            ctrl.text = monthly.toString();
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _prefilling = false);
  }

  double get _totalExpense => _expensePercents.fold(0, (a, b) => a + b);

  Future<void> _save() async {
    // Validate that at least some revenue is entered
    final revenues = _revenueCtrlList.map((c) => double.tryParse(c.text) ?? 0).toList();
    if (revenues.every((r) => r == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter at least one month of revenue data.'),
        backgroundColor: kError,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    // Normalize expense percentages to sum to 100
    final total = _totalExpense;
    final normalizedExpenses = _expensePercents
        .map((p) => (p / total * 100).roundToDouble())
        .toList();

    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _api.uploadFinancials(
        token: token,
        monthlyRevenue: [
          for (int i = 0; i < 6; i++)
            {'month': _monthLabels[i], 'revenue': revenues[i]},
        ],
        expenseBreakdown: [
          for (int i = 0; i < 6; i++)
            {'category': _expenseCategories[i], 'percentage': normalizedExpenses[i]},
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Financial data saved! Your charts are now up to date.'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, true); // return true = data was saved
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: kError,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
        title: Text(
          widget.isPostRegistration ? 'Set Up Financials' : 'Update Financials',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: widget.isPostRegistration
            ? TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip', style: TextStyle(color: kPrimary, fontSize: 13)),
              )
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: kTextDark),
                ),
              ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _prefilling
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), children: [
              // ── Header ─────────────────────────────────────────────────
              if (widget.isPostRegistration) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimary.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                      child: const Icon(Icons.bar_chart_rounded, color: kPrimary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Power Up Your Dashboard',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimary)),
                      const SizedBox(height: 6),
                      const Text(
                          'Enter your revenue & expenses to see personalised charts. You can update these anytime.',
                          style: TextStyle(fontSize: 13, color: kTextMuted, height: 1.4)),
                    ])),
                  ]),
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),
              ],

              // ── Monthly Revenue ─────────────────────────────────────────
              _SectionCard(
                title: 'Monthly Revenue',
                subtitle: 'Enter your revenue for each of the last 6 months',
                icon: Icons.trending_up_rounded,
                child: Column(
                  children: List.generate(6, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      SizedBox(
                        width: 80,
                        child: Text(_monthLabels[i],
                            style: const TextStyle(
                                fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _revenueCtrlList[i],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
                            hintText: '0',
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
                      ),
                    ]),
                  )),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Expense Breakdown ───────────────────────────────────────
              _SectionCard(
                title: 'Expense Breakdown',
                subtitle: 'Drag sliders to set each category\'s share of total expenses',
                icon: Icons.pie_chart_rounded,
                child: Column(children: [
                  // Total indicator
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Allocation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_totalExpense - 100).abs() < 1
                            ? kSuccess.withOpacity(0.1)
                            : kWarning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_totalExpense.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold,
                          color: (_totalExpense - 100).abs() < 1 ? kSuccess : kWarning,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  ...List.generate(6, (i) => Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_expenseCategories[i],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
                      Text('${_expensePercents[i].toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
                    ]),
                    Slider(
                      value: _expensePercents[i],
                      min: 0, max: 60,
                      divisions: 60,
                      activeColor: kPrimary,
                      inactiveColor: kPrimary.withOpacity(0.12),
                      onChanged: (v) => setState(() => _expensePercents[i] = v),
                    ),
                    const SizedBox(height: 8),
                  ])),
                  if ((_totalExpense - 100).abs() > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kWarning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kWarning.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, size: 16, color: kWarning),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Percentages don\'t need to add up exactly — they\'ll be normalised to 100% on save.',
                          style: TextStyle(fontSize: 12, color: kWarning),
                        )),
                      ]),
                    ),
                ]),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent, // Using orange accent for action
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _loading ? 'Saving…' : 'Save Financial Data',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 48),
            ]),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.subtitle, required this.icon, required this.child});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        ],
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: kTextMuted)),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
      child,
    ]),
  );
}
