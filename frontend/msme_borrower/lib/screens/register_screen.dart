import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import 'financial_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _legalCtrl     = TextEditingController();
  final _ownerCtrl     = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _gstinCtrl     = TextEditingController();
  final _turnoverCtrl  = TextEditingController();
  final _profitCtrl    = TextEditingController();
  String _bizType      = 'Manufacturing';
  bool _obscure        = true;

  final List<String> _bizTypes = [
    'Manufacturing', 'Retail', 'IT Services',
    'Agriculture', 'Textile', 'Food Processing', 'Other',
  ];

  @override
  void dispose() {
    for (final c in [_legalCtrl, _ownerCtrl, _emailCtrl, _phoneCtrl,
      _passCtrl, _gstinCtrl, _turnoverCtrl, _profitCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register({
      'legal_name':       _legalCtrl.text.trim(),
      'owner_name':       _ownerCtrl.text.trim(),
      'email':            _emailCtrl.text.trim(),
      'phone':            _phoneCtrl.text.trim(),
      'password':         _passCtrl.text,
      'gstin':            _gstinCtrl.text.isEmpty ? null : _gstinCtrl.text.trim(),
      'business_type':    _bizType,
      'annual_turnover':  double.tryParse(_turnoverCtrl.text.trim()),
      'annual_profit':    double.tryParse(_profitCtrl.text.trim()),
    });
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Account created successfully!'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
      ));
      // Navigate to financial setup (user can skip)
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FinancialSetupScreen(isPostRegistration: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: kError,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Business Registration'),
        backgroundColor: Colors.white,
        foregroundColor: kPrimary,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                   Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: const Icon(Icons.rocket_launch_rounded, color: kAccent, size: 48),
                    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  ),
                  const SizedBox(height: 24),
                  const Text('Join Lendingkart', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimary)),
                  const SizedBox(height: 12),
                  const Text('Complete your profile to get access to fast, collateral-free business loans.', textAlign: TextAlign.center, style: TextStyle(color: kTextMuted, fontSize: 16, height: 1.5)),
                  const SizedBox(height: 48),

                  // ── Business Details Card ──────────────────────────────────────
                  _buildSectionCard(
                    title: 'Business Details',
                    icon: Icons.store_mall_directory_rounded,
                    children: [
                      _field(_legalCtrl, 'Business / Legal Name', Icons.business_rounded, required: true),
                      const SizedBox(height: 20),
                      _field(_ownerCtrl, 'Owner / Proprietor Name', Icons.person_outline_rounded, required: true),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _bizType,
                        decoration: InputDecoration(
                          labelText: 'Business Type', 
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                        ),
                        items: _bizTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _bizType = v!),
                      ),
                      const SizedBox(height: 20),
                      _field(_gstinCtrl, 'GSTIN (optional)', Icons.receipt_long_outlined),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── Contact & Account Card ────────────────────────────────────────
                  _buildSectionCard(
                    title: 'Contact & Account',
                    icon: Icons.contact_mail_rounded,
                    children: [
                      _field(_emailCtrl, 'Business Email', Icons.email_outlined, type: TextInputType.emailAddress, required: true,
                          validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null),
                      const SizedBox(height: 20),
                      _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, type: TextInputType.phone, required: true,
                          validator: (v) => (v?.length ?? 0) < 10 ? 'Enter 10-digit number' : null),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password', 
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── Business Financials Card ───────────────────────────
                  _buildSectionCard(
                    title: 'Business Financials (Annual)',
                    icon: Icons.account_balance_wallet_rounded,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, size: 24, color: Colors.blue[600]),
                          const SizedBox(width: 16),
                          Expanded(child: Text('Entered once at registration — auto-filled on every loan application.', style: TextStyle(fontSize: 14, color: Colors.blue[800], height: 1.4))),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _turnoverCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Annual Turnover (₹)', 
                          prefixIcon: const Icon(Icons.trending_up_rounded), 
                          hintText: 'e.g. 2000000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your annual turnover' : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _profitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Annual Profit (₹)', 
                          prefixIcon: const Icon(Icons.account_balance_rounded), 
                          hintText: 'e.g. 400000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your annual profit' : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                        shadowColor: kAccent.withOpacity(0.4),
                      ),
                      child: auth.loading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('Create Account & Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                            ]),
                    ),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(icon, color: kPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? type, bool required = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
      ),
      validator: validator ?? (required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null),
    );
  }
}
