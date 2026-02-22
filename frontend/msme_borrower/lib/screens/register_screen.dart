import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';

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
        content: Text('✅ Account created! Please log in.'),
        backgroundColor: kSuccess,
      ));
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Business Details ──────────────────────────────────────
            _SectionLabel('Business Details'),
            const SizedBox(height: 12),
            _field(_legalCtrl, 'Business / Legal Name', Icons.business, required: true),
            const SizedBox(height: 14),
            _field(_ownerCtrl, 'Owner / Proprietor Name', Icons.person_outline, required: true),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _bizType,
              decoration: const InputDecoration(
                  labelText: 'Business Type', prefixIcon: Icon(Icons.category_outlined)),
              items: _bizTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _bizType = v!),
            ),
            const SizedBox(height: 14),
            _field(_gstinCtrl, 'GSTIN (optional)', Icons.receipt_long_outlined),

            const SizedBox(height: 28),

            // ── Business Financials (Annual) ───────────────────────────
            _SectionLabel('Business Financials (Annual)'),
            const SizedBox(height: 4),
            const Text(
              'Entered once at registration — auto-filled on every loan application.',
              style: TextStyle(fontSize: 11, color: kTextMuted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _turnoverCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Annual Turnover (₹)',
                prefixIcon: Icon(Icons.trending_up_outlined),
                hintText: 'e.g. 2000000',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your annual turnover'
                  : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _profitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Annual Profit (₹)',
                prefixIcon: Icon(Icons.account_balance_outlined),
                hintText: 'e.g. 400000',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your annual profit'
                  : (double.tryParse(v.trim()) == null ? 'Enter a valid number' : null),
            ),

            // Info box — explains why we collect this
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimary.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: kPrimary),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'These values are saved to your profile and pre-filled '
                  'on every loan application — you won\'t need to enter them again.',
                  style: TextStyle(fontSize: 11, color: kPrimary),
                )),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Contact & Login ────────────────────────────────────────
            _SectionLabel('Contact & Login'),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Business Email', Icons.email_outlined,
                type: TextInputType.emailAddress, required: true,
                validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null),
            const SizedBox(height: 14),
            _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                type: TextInputType.phone, required: true,
                validator: (v) => (v?.length ?? 0) < 10 ? 'Enter 10-digit number' : null),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: auth.loading ? null : _submit,
              child: auth.loading
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, bool required = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator ?? (required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: kPrimary, fontWeight: FontWeight.w600));
}
