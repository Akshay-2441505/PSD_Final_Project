import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool   _hasActiveLoan  = false; // true if borrower already has an approved loan
  String? _activeLoanId;
  double? _activeLoanAmount;
  bool   _hasError       = false;

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
  /// Also checks for an existing active approved loan.
  Future<void> _prefillFromProfile() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final results = await Future.wait([
        _api.getMyProfile(token),
        _api.getMyLoans(token),
      ]);
      if (!mounted) return;
      final profile = results[0] as Map<String, dynamic>;
      final loans   = results[1] as List;
      final turnover = profile['annual_turnover'];
      final profit   = profile['annual_profit'];
      // Check for any active APPROVED loan
      final activeLoan = loans.firstWhere(
        (l) => (l as Map)['status'] == 'APPROVED',
        orElse: () => null,
      ) as Map<String, dynamic>?;
      setState(() {
        if (turnover != null) _turnoverCtrl.text = turnover.toString();
        if (profit   != null) _profitCtrl.text   = profit.toString();
        _profileLoaded   = (turnover != null);
        _hasActiveLoan   = activeLoan != null;
        _activeLoanId    = activeLoan?['app_id'] as String?;
        _activeLoanAmount = activeLoan != null
            ? (activeLoan['requested_amount'] as num?)?.toDouble()
            : null;
      });
    } catch (_) {} // silent — user can always fill manually
  }

  @override
  void dispose() { _turnoverCtrl.dispose(); _profitCtrl.dispose(); super.dispose(); }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _hasError = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _hasError = false);
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _api.applyLoan({
        'requested_amount':  _amount,
        'tenure_months':     _tenure,
        'purpose':           _purpose,
        'declared_turnover': double.tryParse(_turnoverCtrl.text), // null if empty → backend uses profile value
        'declared_profit':   double.tryParse(_profitCtrl.text),   // null if empty → backend uses profile value
      }, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Loan application submitted!'), backgroundColor: kSuccess),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Detect 409 active-loan conflict
      if (msg.contains('ACTIVE_LOAN_EXISTS') || msg.contains('409')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.info_rounded, color: kWarning),
              SizedBox(width: 8),
              Text('Active Loan Exists', style: TextStyle(fontSize: 16)),
            ]),
            content: const Text(
              'You already have an approved loan that is currently active.\n\n'
              'Please repay your existing loan before applying for a new one.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: const Text('View My Loans', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.replaceAll('Exception: ', '')),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Apply for Business Loan')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), children: [
          
          const Text('Configure Your Loan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 6),
          const Text('Adjust the amount and tenure to fit your business needs.', style: TextStyle(fontSize: 14, color: kTextMuted)),
          const SizedBox(height: 24),

          // ── Active Loan Warning Banner ─────────────────────────────
          if (_hasActiveLoan) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWarning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kWarning.withOpacity(0.4), width: 1.5),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, color: kWarning, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Active Loan Detected',
                      style: TextStyle(fontWeight: FontWeight.w700, color: kWarning, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'You already have an approved loan'
                    '${_activeLoanAmount != null ? " of ₹${_fmtAmount(_activeLoanAmount!)}" : ""}.'
                    ' You must repay it before applying for a new one.',
                    style: const TextStyle(fontSize: 13, color: kTextDark, height: 1.5),
                  ),
                ])),
              ]),
            ).animate().fadeIn().slideY(begin: -0.1),
          ],

          // ── Loan Amount & Tenure Card ─────────────────────────────────────
          _Card(children: [
            _Label('Loan Amount Required'),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹ ${_fmtAmount(_amount)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimary, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kPrimary,
                inactiveTrackColor: kPrimary.withOpacity(0.1),
                thumbColor: kPrimary,
                overlayColor: kPrimary.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _amount, min: 50000, max: 2000000,
                divisions: 39,
                label: '₹ ${_fmtAmount(_amount)}',
                onChanged: (v) => setState(() => _amount = v.roundToDouble()),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('₹ 50K', style: TextStyle(fontSize: 12, color: kTextMuted)),
              const Text('₹ 20L', style: TextStyle(fontSize: 12, color: kTextMuted)),
            ]),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),

            _Label('Repayment Tenure'),
            const SizedBox(height: 12),
            Text('$_tenure months',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kPrimary,
                inactiveTrackColor: kPrimary.withOpacity(0.1),
                thumbColor: kPrimary,
                overlayColor: kPrimary.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _tenure.toDouble(), min: 3, max: 60,
                divisions: 19,
                label: '$_tenure months',
                onChanged: (v) => setState(() => _tenure = v.toInt()),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('3 months', style: TextStyle(fontSize: 12, color: kTextMuted)),
              const Text('60 months', style: TextStyle(fontSize: 12, color: kTextMuted)),
            ]),
          ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),

          // ── EMI & Interest Rate Summary ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estimated EMI', style: TextStyle(fontSize: 13, color: kTextMuted)),
                const SizedBox(height: 4),
                Text('₹ ${emiCalc.toStringAsFixed(0)} /mo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
              ])),
              Container(width: 1, height: 40, color: const Color(0xFFCBD5E1), margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Interest Rate', style: TextStyle(fontSize: 13, color: kTextMuted)),
                const SizedBox(height: 4),
                const Text('12% p.a.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
              ])),
            ]),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // ── Loan Purpose ───────────────────────────────────────────
          _Card(children: [
            _Label('What is the loan for?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _purpose,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
              items: _purposes.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!))).toList(),
              onChanged: (v) => setState(() => _purpose = v!),
            ),
          ]).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // ── Financial Declaration ──────────────────────────────────
          _Card(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Label('Business Financials'),
              if (_profileLoaded && !_editFinancials)
                GestureDetector(
                  onTap: () => setState(() => _editFinancials = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_outlined, size: 12, color: kTextDark),
                      SizedBox(width: 4),
                      Text('Override', style: TextStyle(fontSize: 11, color: kTextDark, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              if (_profileLoaded && _editFinancials)
                GestureDetector(
                  onTap: () => setState(() => _editFinancials = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock_reset, size: 12, color: kWarning),
                      SizedBox(width: 4),
                      Text('Restore profile', style: TextStyle(fontSize: 11, color: kWarning, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 16),

            // Read-only display when loaded from profile (and user hasn't overridden)
            if (_profileLoaded && !_editFinancials) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: kSuccess),
                    const SizedBox(width: 6),
                    const Text('Auto-filled from your profile', style: TextStyle(fontSize: 12, color: kSuccess, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _ReadOnlyField(
                      label: 'Annual Turnover',
                      value: _turnoverCtrl.text.isNotEmpty
                          ? '₹ ${_fmtReadable(_turnoverCtrl.text)}'
                          : '—',
                      icon: Icons.trending_up_outlined,
                    )),
                    const SizedBox(width: 16),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Annual financials not found in your profile. Please enter manually.',
                    style: TextStyle(fontSize: 12, color: kError, fontWeight: FontWeight.w500),
                  ),
                ),
              if (_editFinancials)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: kWarning.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: kWarning),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Overriding profile values for this application only.',
                      style: TextStyle(fontSize: 12, color: kWarning),
                    )),
                  ]),
                ),
              TextFormField(
                controller: _turnoverCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Annual Turnover (₹)', prefixIcon: Icon(Icons.trending_up_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _profitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Annual Profit (₹)', prefixIcon: Icon(Icons.account_balance_outlined)),
              ),
            ],
          ]).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // ── Account Aggregator ─────────────────────────────────────
          _Card(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Label('Verify Bank Statements'),
                const SizedBox(height: 6),
                const Text('Link your bank account via Account Aggregator for instant verification.',
                    style: TextStyle(fontSize: 12, color: kTextMuted, height: 1.4)),
              ])),
              Switch(value: _aaFetch, activeColor: kSuccess,
                  onChanged: (v) => setState(() => _aaFetch = v)),
            ]),
            if (_aaFetch)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSuccess.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: kSuccess, size: 16),
                    SizedBox(width: 8),
                    Text('Data will be fetched securely', style: TextStyle(fontSize: 13, color: kSuccess, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
          ]).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),

          // ── Submit ─────────────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent, // Primary action color
              ),
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ).animate(delay: 500.ms).fadeIn(),
          const SizedBox(height: 48),
        ]),
      ).animate(target: _hasError ? 1 : 0).shakeX(amount: 4, hz: 8),
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
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark));
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
