import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double>   _cardScale;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardScale =
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 100), _cardCtrl.forward);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
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
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) {
          final t = _bgCtrl.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF6A3FA0), const Color(0xFF4A2E80), t)!,
                  Color.lerp(const Color(0xFF7C5CBF), const Color(0xFF9B6BD1), t)!,
                  Color.lerp(const Color(0xFFB39DDB), const Color(0xFFFF9472), t)!,
                ],
              ),
            ),
            child: Stack(children: [
              // Decorative background blobs
              Positioned(top: -80, right: -80,
                  child: _Blob(size: 240, color: Colors.white.withOpacity(0.07))),
              Positioned(bottom: 60, left: -100,
                  child: _Blob(size: 320, color: Colors.white.withOpacity(0.05))),
              Positioned(top: 200, left: 30,
                  child: _Blob(size: 80, color: Colors.white.withOpacity(0.06))),

              // Card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 48,
                              offset: const Offset(0, 20)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Brand ──────────────────────────────────
                            Column(children: [
                              Container(
                                width: 76, height: 76,
                                decoration: BoxDecoration(
                                  gradient: kHeroGradient,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [BoxShadow(
                                      color: kPrimary.withOpacity(0.45),
                                      blurRadius: 22,
                                      offset: const Offset(0, 8))],
                                ),
                                child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white, size: 38),
                              ),
                              const SizedBox(height: 16),
                              Text('MSME Lending',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: kTextDark,
                                      letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Your business, funded in 48 hours ⚡',
                                  style: const TextStyle(
                                      fontSize: 12, color: kTextMuted)),
                            ]),
                            const SizedBox(height: 32),

                            // ── Heading ─────────────────────────────────
                            const Text('Welcome back 👋',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: kTextDark)),
                            const SizedBox(height: 4),
                            const Text('Sign in to your account',
                                style: TextStyle(fontSize: 13, color: kTextMuted)),
                            const SizedBox(height: 24),

                            // ── Email ───────────────────────────────────
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Business Email',
                                  prefixIcon: Icon(Icons.email_outlined)),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // ── Password ────────────────────────────────
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? 'Password too short'
                                      : null,
                            ),
                            const SizedBox(height: 28),

                            // ── Login Button ────────────────────────────
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: auth.loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  elevation: 4,
                                  shadowColor: kPrimary.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: auth.loading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Register link ────────────────────────────
                            Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              const Text("New here? ",
                                  style: TextStyle(color: kTextMuted, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen())),
                                child: const Text('Create account',
                                    style: TextStyle(
                                        color: kPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

extension WidgetAlso on Widget {
  Widget also(Widget Function(Widget) fn) => fn(this);
}
