import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side branding (Visible on wide screens, or takes top half on mobile)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: kPrimary,
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1542744173-8e7e53415bb0?q=80&w=2070&auto=format&fit=crop'), // Placeholder for professional business image
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(kPrimary, BlendMode.softLight),
                  ),
                ),
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('LENDINGKART', style: kHeading1(context).copyWith(color: Colors.white, fontSize: 32, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text('Simplifying MSME Finance', style: kHeading2(context).copyWith(color: kAccent, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 48),
                    Text('Fast-track Your Business\nwith an Unsecured Loan', style: kHeading1(context).copyWith(color: Colors.white, fontSize: 42, height: 1.2)),
                    const SizedBox(height: 24),
                    _FeatureItem(icon: Icons.check_circle_outline, text: 'No Collateral Needed'),
                    const SizedBox(height: 12),
                    _FeatureItem(icon: Icons.check_circle_outline, text: 'Flexible Loan Range upto ₹50 Lakhs'),
                  ],
                ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
              ),
            ),
          
          // Right side Login Form
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (MediaQuery.of(context).size.width <= 800) ...[
                          Center(
                            child: Text('LENDINGKART', style: kHeading1(context).copyWith(color: kPrimary, fontSize: 28, letterSpacing: 1)),
                          ),
                          Center(
                            child: Text('Simplifying MSME Finance', style: kCaption(context).copyWith(color: kAccent, fontStyle: FontStyle.italic, fontSize: 13)),
                          ),
                          const SizedBox(height: 48),
                        ],

                        // ── Heading ─────────────────────────────────
                        Text('Existing User', style: kHeading1(context).copyWith(color: kPrimary)),
                        const SizedBox(height: 8),
                        Text('Welcome back! Enter details to proceed', style: TextStyle(fontSize: 15, color: kTextMuted)),
                        const SizedBox(height: 36),

                        // ── Email ───────────────────────────────────
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Business Email ID',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 20),

                        // ── Password ────────────────────────────────
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                        ),
                        const SizedBox(height: 32),

                        // ── Login Button ────────────────────────────
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: auth.loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            child: auth.loading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),   
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Divider ────────────────────────────
                        Row(children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ]),
                        const SizedBox(height: 32),

                        // ── Register link ────────────────────────────
                        Text('New User', style: kHeading1(context).copyWith(color: kPrimary, fontSize: 24)),
                        const SizedBox(height: 8),
                         Text('New to Lendingkart? Apply for Business Loan', style: TextStyle(fontSize: 15, color: kTextMuted)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kAccent,
                              side: const BorderSide(color: kAccent, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                Text('Apply Now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),   
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
