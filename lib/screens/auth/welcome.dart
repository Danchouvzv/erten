import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../auth_service.dart';
import '../../main.dart';
import '../../ui_kit.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackdrop(intense: true),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AuthTopBar(showBack: false),
                  const Spacer(),
                  const _HeroMark(),
                  const SizedBox(height: 30),
                  const Text(
                    'Design tomorrow before it starts.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erten turns your energy, calendar pressure and goals into one clear execution plan.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 17,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _WelcomeHighlights(),
                  const Spacer(),
                  AppPrimaryButton(
                    label: 'Create account',
                    icon: CupertinoIcons.person_crop_circle_badge_plus,
                    onTap: () => _push(context, const RegisterScreen()),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryAuthButton(
                    label: 'Sign in',
                    icon: CupertinoIcons.arrow_right_circle,
                    onTap: () => _push(context, const LoginScreen()),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => _enterApp(context),
                      child: const Text(
                        'Continue as guest',
                        style: TextStyle(
                          color: AppColors.labelGray,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      _showAuthError(context, error);
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) return;
    _enterApp(context);
  }

  Future<void> _resetPassword() async {
    final error = _validateEmail(_emailController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    try {
      await AuthService.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showAuthError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in to keep your contracts, streaks and debrief history synced.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthTextField(
              controller: _emailController,
              label: 'Email',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _passwordController,
              label: 'Password',
              icon: CupertinoIcons.lock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onSubmitted: (_) => _submit(),
              trailing: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  color: AppColors.labelGray,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.orangeSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SubmitButton(
              label: 'Sign in',
              icon: CupertinoIcons.arrow_right,
              isLoading: _isSubmitting,
              onTap: _submit,
            ),
            const SizedBox(height: 22),
            _AuthSwitchLine(
              text: 'New to Erten?',
              action: 'Create account',
              onTap: () => _replace(context, const RegisterScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreed = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accept the terms to continue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      _showAuthError(context, error);
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) return;
    _enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Create your account',
      subtitle:
          'Save plans, unlock identity progress and keep your execution data safe.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthTextField(
              controller: _nameController,
              label: 'Name',
              icon: CupertinoIcons.person,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _emailController,
              label: 'Email',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _passwordController,
              label: 'Password',
              icon: CupertinoIcons.lock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onSubmitted: (_) => _submit(),
              trailing: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  color: AppColors.labelGray,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TermsRow(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value),
            ),
            const SizedBox(height: 22),
            _SubmitButton(
              label: 'Create account',
              icon: CupertinoIcons.checkmark_alt,
              isLoading: _isSubmitting,
              onTap: _submit,
            ),
            const SizedBox(height: 22),
            _AuthSwitchLine(
              text: 'Already have an account?',
              action: 'Sign in',
              onTap: () => _replace(context, const LoginScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AppBackdrop(intense: true),
          SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: _AuthTopBar(),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _FrostedPanel(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({this.showBack = true});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          _CircleButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => Navigator.of(context).maybePop(),
          )
        else
          const _AppGlyph(),
        const Spacer(),
        AppBadge(
          label: AuthService.isReady ? 'Firebase live' : 'Firebase setup',
          icon: AuthService.isReady
              ? CupertinoIcons.cloud_fill
              : CupertinoIcons.cloud,
        ),
      ],
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 8,
            child: _MetricTile(
              label: 'Energy',
              value: '82%',
              icon: CupertinoIcons.flame_fill,
              width: 146,
            ),
          ),
          const Positioned(
            right: 2,
            top: 0,
            child: _MetricTile(
              label: 'Streak',
              value: '7d',
              icon: CupertinoIcons.bolt_fill,
              width: 122,
            ),
          ),
          Positioned(
            left: 54,
            right: 26,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      const _AppGlyph(size: 54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tomorrow plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: 0.68,
                                backgroundColor: Colors.white.withOpacity(0.10),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _WelcomeHighlights extends StatelessWidget {
  const _WelcomeHighlights();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _HighlightPill(
            icon: CupertinoIcons.calendar,
            label: 'AI schedule',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HighlightPill(
            icon: CupertinoIcons.chart_bar_alt_fill,
            label: 'Streaks',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HighlightPill(
            icon: CupertinoIcons.lock_shield_fill,
            label: 'Sync',
          ),
        ),
      ],
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 20),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBlack.withOpacity(0.80),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.trailing,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      cursorColor: AppColors.primaryOrange,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.labelGray,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryOrange, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.white.withOpacity(0.065),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFFF453A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFFF453A)),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [AppColors.primaryOrange, AppColors.orangeSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.25),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.black, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAuthButton extends StatelessWidget {
  const _SecondaryAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.085),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthSwitchLine extends StatelessWidget {
  const _AuthSwitchLine({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.labelGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.orangeSoft,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: value
                    ? AppColors.primaryOrange
                    : Colors.white.withOpacity(0.18),
              ),
            ),
            child: value
                ? const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Colors.black,
                    size: 17,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep my execution data synced securely.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.66),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 18),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.labelGray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppGlyph extends StatelessWidget {
  const _AppGlyph({this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.35),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryOrange, Color(0xFFFFB062)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'E',
        style: TextStyle(
          color: Colors.black,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 360),
    ),
  );
}

void _replace(BuildContext context, Widget screen) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 260),
    ),
  );
}

void _enterApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainNavigationScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 520),
    ),
    (_) => false,
  );
}

void _showAuthError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AuthService.userMessage(error))),
  );
}

String? _validateEmail(String? value) {
  final email = (value ?? '').trim();
  final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  if (!isValid) return 'Enter a valid email.';
  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').length < 6) {
    return 'Use at least 6 characters.';
  }
  return null;
}
