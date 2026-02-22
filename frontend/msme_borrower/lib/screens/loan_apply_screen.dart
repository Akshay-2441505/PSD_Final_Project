import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';

class LoanApplyScreen extends StatefulWidget {
  const LoanApplyScreen({super.key});
  @override State<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends State<LoanApplyScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _api           = ApiService();
  final _turnoverCtrl  = TextEditingController();
  final _profitCtrl    = TextEditingController();

  double _amount   = 100000;
  int    _tenure   = 12;
  String _purpose  = 'WORKING_CAPITAL';
  bool   _loading       = false;
  bool   _aaFetch        = false;
  bool   _profileLoaded  = false; // true once financials auto-filled
  bool   _editFinancials = false; // unlocked by user explicitly

  final List<Map<String,String>> _purposes = [
    {'value': 'WORKING_CAPITAL',   'label': 'Working Capital'},
    {'value': 'EQUIPMENT_PURCHASE','label': 'Equipment Purchase'},
    {'value': 'INVENTORY',         'label': 'Inventory'},
    {'value': 'EXPANSION',         'label': 'Business Expansion'},
    {'value': 'OTHER',             'label': 'Other'},
  ];

  double get _emi {
    final r = 0.01; // 1% monthly interest (mock)
    final n = _tenure.toDouble();
    return (_amount * r * (1 + r).toDouble()) /
        ((1 + r).toDouble() - 1).abs().clamp(0.001, double.infinity) *
        (n == 0 ? 1 : 1);
    // Simple EMI = P * r * (1+r)^n / ((1+r)^n - 1)
  }

  // Better EMI calculation
  double get emiCalc {
    const r = 0.01;
    final n = _tenure;
    if (n == 0) return 0;
    final factor = (1 + r) * (1 + r);
    // Use formula: P*r*(1+r)^n / ((1+r)^n - 1)
    double pow = 1.0;
    for (int i = 0; i < n; i++) pow *= (1 + r);
    return (_amount * r * pow) / (pow - 1);
  }

  @override
  void initState() {
    super.initState();
    // Fetch stored profile financials to auto-fill the form
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  /// Reads the borrower's stored annual_turnover & annual_profit from their profile
  /// (set during registration) and pre-fills the form. The user can still edit.
  Future<void> _prefillFromProfile() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final profile = await _api.getMyProfile(token);
      if (!mounted) return;
      final turnover = profile['annual_turnover'];
      final profit   = profile['annual_profit'];
      setState(() {
        if (turnover != null) _turnoverCtrl.text = turnover.toString();
        if (profit   != null) _profitCtrl.text   = profit.toString();
        _profileLoaded = (turnover != null);
      });
    } catch (_) {} // silent — user can always fill manually
  }

  @override
  void dispose() { _turnoverCtrl.dispose(); _profitCtrl.dispose(); super.dispose(); }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _api.applyLoan({
        'requested_amount':  _amount,
        'tenure_months':     _tenure,
        'purpose':           _purpose,
        'declared_turnover': double.tryParse(_turnoverCtrl.text) ?? 0,
        'declared_profit':   double.tryParse(_profitCtrl.text) ?? 0,
      }, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Loan application submitted!'), backgroundColor: kSuccess),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: kError),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          // ── Loan Amount Slider ─────────────────────────────────────
          _Card(children: [
            _Label('Loan Amount'),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹ ${_fmtAmount(_amount)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                child: Text('EMI ≈ ₹ ${emiCalc.toStringAsFixed(0)}/mo',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
              ),
            ]),
            Slider(
              value: _amount, min: 50000, max: 2000000,
              divisions: 39, activeColor: kPrimary,
              label: '₹ ${_fmtAmount(_amount)}',
              onChanged: (v) => setState(() => _amount = v.roundToDouble()),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹ 50K', style: const TextStyle(fontSize: 11, color: kTextMuted)),
              Text('₹ 20L', style: const TextStyle(fontSize: 11, color: kTextMuted)),
            ]),
          ]),
          const SizedBox(height: 16),

          // ── Tenure Slider ──────────────────────────────────────────
          _Card(children: [
            _Label('Tenure'),
            const SizedBox(height: 8),
            Text('$_tenure months',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kPrimary)),
            Slider(
              value: _tenure.toDouble(), min: 3, max: 60,
              divisions: 19, activeColor: kPrimary,
              label: '$_tenure months',
              onChanged: (v) => setState(() => _tenure = v.toInt()),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('3 months', style: const TextStyle(fontSize: 11, color: kTextMuted)),
              Text('60 months', style: const TextStyle(fontSize: 11, color: kTextMuted)),
            ]),
          ]),
          const SizedBox(height: 16),

          // ── Loan Purpose ───────────────────────────────────────────
          _Card(children: [
            _Label('Loan Purpose'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _purpose,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined), border: InputBorder.none, filled: false),
              items: _purposes.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!))).toList(),
              onChanged: (v) => setState(() => _purpose = v!),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Financial Declaration ──────────────────────────────────
          _Card(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Label('Business Financials (Annual)'),
              if (_profileLoaded && !_editFinancials)
                GestureDetector(
                  onTap: () => setState(() => _editFinancials = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_outlined, size: 11, color: kPrimary),
                      SizedBox(width: 4),
                      Text('Override', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              if (_profileLoaded && _editFinancials)
                GestureDetector(
                  onTap: () => setState(() => _editFinancials = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock_reset, size: 11, color: kWarning),
                      SizedBox(width: 4),
                      Text('Restore profile', style: TextStyle(fontSize: 10, color: kWarning, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 10),

            // Read-only display when loaded from profile (and user hasn't overridden)
            if (_profileLoaded && !_editFinancials) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDDAEE)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.lock_outline, size: 14, color: kTextMuted),
                    const SizedBox(width: 6),
                    const Text('From your profile', style: TextStyle(fontSize: 11, color: kTextMuted)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _ReadOnlyField(
                      label: 'Annual Turnover',
                      value: _turnoverCtrl.text.isNotEmpty
                          ? '₹ ${_fmtReadable(_turnoverCtrl.text)}'
                          : '—',
                      icon: Icons.trending_up_outlined,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ReadOnlyField(
                      label: 'Annual Profit',
                      value: _profitCtrl.text.isNotEmpty
                          ? '₹ ${_fmtReadable(_profitCtrl.text)}'
                          : '—',
                      icon: Icons.account_balance_outlined,
                    )),
                  ]),
                ]),
              ),
            ] else ...[
              // Editable fields when not loaded from profile or user overrides
              if (!_profileLoaded)
                const Text(
                  'Annual financials not found in your profile. Please enter manually.',
                  style: TextStyle(fontSize: 11, color: kError),
                ),
              if (_editFinancials)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kWarning.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, size: 13, color: kWarning),
                    SizedBox(width: 6),
                    Expanded(child: Text(
                      'Overriding profile values for this application only.',
                      style: TextStyle(fontSize: 11, color: kWarning),
                    )),
                  ]),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _turnoverCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Annual Turnover (₹)', prefixIcon: Icon(Icons.trending_up_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _profitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Annual Profit (₹)', prefixIcon: Icon(Icons.account_balance_outlined)),
              ),
            ],
          ]),
          const SizedBox(height: 16),

          // ── Account Aggregator ─────────────────────────────────────
          _Card(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Label('Link Bank Account'),
                const SizedBox(height: 4),
                const Text('Share 6-month bank statement via Account Aggregator (simulated)',
                    style: TextStyle(fontSize: 11, color: kTextMuted)),
              ])),
              Switch(value: _aaFetch, activeColor: kPrimary,
                  onChanged: (v) => setState(() => _aaFetch = v)),
            ]),
            if (_aaFetch)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: kSuccess, size: 16),
                    SizedBox(width: 8),
                    Text('Bank data will be fetched automatically', style: TextStyle(fontSize: 12, color: kSuccess)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 28),

          // ── Submit ─────────────────────────────────────────────────
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application'),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  String _fmtAmount(double v) => v >= 100000
      ? '${(v / 100000).toStringAsFixed(v.remainder(100000) == 0 ? 0 : 1)}L'
      : '${(v / 1000).toStringAsFixed(0)}K';

  String _fmtReadable(String raw) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(1)} L';
    if (v >= 1000)     return '${(v / 1000).toStringAsFixed(0)} K';
    return v.toStringAsFixed(0);
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary));
}

class _ReadOnlyField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ReadOnlyField({required this.label, required this.value, required this.icon});
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, size: 13, color: kTextMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
    ]),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
  ]);
}
