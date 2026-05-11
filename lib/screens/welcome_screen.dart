import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

// need TickerProviderStateMixin kasi dalawa ang AnimationController
// yung isa para sa tab, yung isa para sa floating logo
class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();

  late TabController _tabCtrl;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorText;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      // clear error pag nagpalit ng tab
      if (mounted) setState(() => _errorText = null);
    });

    // yung float animation ng logo — pataas pababa
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // stop muna bago i-dispose para hindi mag-error
    _floatCtrl.stop();
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields. ✏️');
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });
    try {
      await _auth.signIn(email: email, password: pass);
      // AuthWrapper sa main.dart na bahala sa redirect
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorText = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    // validation checks
    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields. ✏️');
      return;
    }
    if (name.length > 10) {
      setState(() => _errorText = 'Name can only be up to 10 characters! ✂️');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters. 🔒');
      return;
    }
    if (pass.length > 12) {
      setState(() => _errorText = 'Password can only be up to 12 characters! ✂️');
      return;
    }
    // letters and numbers only — no special characters
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(pass)) {
      setState(() => _errorText = 'No special characters in password! 🙅');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorText = 'Passwords don\'t match. 🔑');
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });
    try {
      await _auth.register(name: name, email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorText = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        // bg.png as background
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // wide screen = logo sa kaliwa, form sa kanan (side by side)
                // narrow screen = stacked (para sa mobile)
                final isWide = constraints.maxWidth > 700;

                // floating logo animation
                final floatingLogo = AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Image.asset(
                      'assets/logo.png',
                      height: constraints.maxHeight * 0.28,
                      fit: BoxFit.contain,
                    ),
                  ),
                );

                // the login/register card
                final formCard = _buildFormCard();

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // logo takes up the left side
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _floatAnim,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(0, _floatAnim.value),
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: constraints.maxHeight * 0.85,
                                  width: constraints.maxWidth * 0.52,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // form on the right
                        Expanded(
                          flex: 4,
                          child: Center(child: formCard),
                        ),
                      ],
                    ),
                  );
                }

                // narrow/mobile layout
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      floatingLogo,
                      const SizedBox(height: 20),
                      formCard,
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // separated this out para hindi masyadong mahabang build method
  Widget _buildFormCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // tab bar — Sign In / Register
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
              unselectedLabelStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFFF6B9D),
              tabs: const [
                Tab(text: '🔑  Sign In'),
                Tab(text: '🌟  Register'),
              ],
            ),
          ),

          // form fields
          SizedBox(
            height: _tabCtrl.index == 0 ? 200 : 380,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SignInForm(
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  obscurePass: _obscurePass,
                  onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                  onSubmit: _signIn,
                ),
                _RegisterForm(
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  confirmCtrl: _confirmCtrl,
                  obscurePass: _obscurePass,
                  obscureConfirm: _obscureConfirm,
                  onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                  onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmit: _register,
                ),
              ],
            ),
          ),

          // error message — lalabas lang kung may error
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                ),
                child: Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF4444),
                  ),
                ),
              ),
            ),

          // submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)))
                : _HoverButton(
                    onTap: _tabCtrl.index == 0 ? _signIn : _register,
                    label: _tabCtrl.index == 0 ? '🖌️  Let\'s Paint!' : '🌈  Create Account!',
                  ),
          ),
        ],
      ),
    );
  }
}

// submit button with hover and press effects
class _HoverButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _HoverButton({required this.onTap, required this.label});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) setState(() { _hovered = false; _pressed = false; });
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(_hovered ? 0.55 : 0.35),
                  blurRadius: _pressed ? 6 : (_hovered ? 22 : 14),
                  offset: _pressed ? const Offset(0, 2) : const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// sign in form — email + password lang
class _SignInForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscurePass;
  final VoidCallback onTogglePass;
  final VoidCallback onSubmit;

  const _SignInForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscurePass,
    required this.onTogglePass,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          _AuthField(
            controller: emailCtrl,
            hint: 'Email address',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _AuthField(
            controller: passCtrl,
            hint: 'Password',
            icon: Icons.lock_rounded,
            obscure: obscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFFFF6B9D),
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}

// register form — name, email, password, confirm
class _RegisterForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const _RegisterForm({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          _AuthField(
            controller: nameCtrl,
            hint: 'Your name (max 10 chars)',
            icon: Icons.person_rounded,
            textCapitalization: TextCapitalization.words,
            maxLength: 10,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
          ),
          const SizedBox(height: 8),
          _AuthField(
            controller: emailCtrl,
            hint: 'Email address',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          _AuthField(
            controller: passCtrl,
            hint: 'Password (6–12 chars, no symbols)',
            icon: Icons.lock_rounded,
            obscure: obscurePass,
            maxLength: 12,
            inputFormatters: [
              LengthLimitingTextInputFormatter(12),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            suffixIcon: IconButton(
              icon: Icon(
                obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFFFF6B9D),
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ),
          const SizedBox(height: 8),
          _AuthField(
            controller: confirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscure: obscureConfirm,
            maxLength: 12,
            inputFormatters: [
              LengthLimitingTextInputFormatter(12),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFFFF6B9D),
                size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}

// reusable text field used by both sign in and register forms
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.onSubmitted,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF5C4033),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B9D), size: 20),
        suffixIcon: suffixIcon,
        counterStyle: GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFFFF0F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
        ),
      ),
    );
  }
}
