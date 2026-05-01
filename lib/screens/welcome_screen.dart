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

// TickerProviderStateMixin kasi dalawa ang controller — bounce + tab
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

  // yung float animation ng logo
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 2, vsync: this);
    // mounted check para hindi mag-setState pag disposed na
    _tabCtrl.addListener(() {
      if (mounted) setState(() => _errorText = null);
    });

    // gentle float — up and down lang, walang bounce na masyado
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
    // stop the animation first before disposing — para hindi mag-tick after dispose
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
      setState(() => _errorText = 'Input please! ✏️');
      return;
    }
    setState(() { _isLoading = true; _errorText = null; });
    try {
      await _auth.signIn(email: email, password: pass);
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

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _errorText = 'Input please! ✏️');
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
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(pass)) {
      setState(() => _errorText = 'No special characters in password please! 🙅');
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // clean white background — 

              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // wide screen (desktop/browser) — logo kaliwa, form kanan
                    final isWide = constraints.maxWidth > 700;

                    final floatingLogo = AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Image.asset(
                          'assets/logo.png',
                          // narrow screen — smaller
                          height: constraints.maxHeight * 0.28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );

                    final formCard = Container(
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
                          // tab switcher
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
                              labelStyle: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              unselectedLabelStyle: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFFFF6B9D),
                              tabs: const [
                                Tab(text: '🔑  Sign In'),
                                Tab(text: '🌟  Register'),
                              ],
                            ),
                          ),

                          // form fields — fixed height per tab, no scroll
                          SizedBox(
                            height: _tabCtrl.index == 0 ? 200 : 340,
                            child: TabBarView(
                              controller: _tabCtrl,
                              children: [
                                _SignInForm(
                                  emailCtrl: _emailCtrl,
                                  passCtrl: _passCtrl,
                                  obscurePass: _obscurePass,
                                  onTogglePass: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                  onSubmit: _signIn,
                                ),
                                _RegisterForm(
                                  nameCtrl: _nameCtrl,
                                  emailCtrl: _emailCtrl,
                                  passCtrl: _passCtrl,
                                  confirmCtrl: _confirmCtrl,
                                  obscurePass: _obscurePass,
                                  obscureConfirm: _obscureConfirm,
                                  onTogglePass: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                  onToggleConfirm: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  onSubmit: _register,
                                ),
                              ],
                            ),
                          ),

                          // error box
                          if (_errorText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFFF6B6B)
                                          .withOpacity(0.4)),
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
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFFFF6B9D)))
                                : _HoverButton(
                                    onTap: _tabCtrl.index == 0
                                        ? _signIn
                                        : _register,
                                    label: _tabCtrl.index == 0
                                        ? '🖌️  Let\'s Paint!'
                                        : '🌈  Create Account!',
                                  ),
                          ),
                        ],
                      ),
                    );

                    if (isWide) {
                      // side by side — logo left, form right
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _floatAnim,
                                  builder: (_, __) => Transform.translate(
                                    offset: Offset(0, _floatAnim.value),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      // fill ~85% of the available height
                                      height: constraints.maxHeight * 0.85,
                                      width: constraints.maxWidth * 0.52,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Center(child: formCard),
                            ),
                          ],
                        ),
                      );
                    }

                    // narrow screen — stacked, with scroll just in case
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}

// --- main submit button with hover + press effect ---

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
    // shadow gets bigger on hover, smaller on press
    final shadowBlur = _pressed ? 6.0 : (_hovered ? 22.0 : 14.0);
    final shadowOffset = _pressed ? const Offset(0, 2) : const Offset(0, 6);
    final scale = _pressed ? 0.97 : (_hovered ? 1.02 : 1.0);

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
          scale: scale,
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
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
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

// --- Sign In form ---

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

// --- Register form --- 

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

// --- reusable text field ---

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

