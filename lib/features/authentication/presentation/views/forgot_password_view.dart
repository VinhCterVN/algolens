import 'dart:async';

import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_form_view_model.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_session_controller.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_validators.dart';
import 'package:algolens/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, required this.repository, required this.session});

  final AuthRepository repository;
  final AuthSessionController session;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailForm = GlobalKey<FormState>(), _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController(), _confirm = TextEditingController();
  final _model = AuthFormViewModel();
  String? _sentEmail;
  String _code = '';
  int _resendSeconds = 0;
  bool _visible = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _model.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_resendSeconds > 0 || !_emailForm.currentState!.validate()) return;
    final email = _email.text.trim();
    final success = await _model.run(
      () => widget.repository.sendRecoveryCode(email),
      successMessage: 'If an account exists for this email, a recovery email has been sent.',
    );
    if (success && mounted) {
      setState(() {
        _sentEmail = email;
        _startTimer();
      });
    }
  }

  Future<void> _verify() async {
    if (_sentEmail == null) return;
    final error = AuthValidators.code(_code);
    if (error != null) {
      setState(() => _model.error = error);
      return;
    }
    widget.session.beginRecovery();
    final success = await _model.run(() => widget.repository.verifyRecoveryCode(_sentEmail!, _code));
    if (!success) widget.session.finishRecovery();
  }

  Future<void> _updatePassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    final success = await _model.run(() => widget.repository.updatePassword(_password.text));
    if (success) widget.session.finishRecovery();
  }

  Future<void> _back() async {
    if (_model.busy) return;
    if (widget.session.isRecovering && widget.session.isSignedIn) {
      final success = await _model.run(widget.repository.signOut);
      if (!success) return;
    }
    widget.session.finishRecovery();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_model, widget.session]),
    builder: (context, _) {
      final verified = widget.session.isRecovering && widget.session.isSignedIn;
      return AuthScaffold(
        title: 'Reset Password',
        topPadding: 8,
        assetPrefix: 'forgot',
        backAsset: 'imgContainer8',
        userAsset: 'imgContainer9',
        onBack: _back,
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
                    child: const FigmaIcon('forgot_imgContainer'),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const FigmaIcon('forgot_imgContainer1'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Account Password',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.65),
            ),
            const SizedBox(height: 4),
            Text(
              verified
                  ? 'Your email is verified. Choose a new password to return to your workspace.'
                  : 'Enter the email associated with your AlgoLens profile. We will dispatch a secure 6-digit verification token to reset your credentials.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: authMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            AuthCard(
              padding: 16,
              background: authPanel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FigmaIcon('forgot_imgContainer2'),
                      const SizedBox(width: 4),
                      Text('ACCOUNT RECOVERY', style: mono(11).copyWith(color: authInk, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'For campus SSO or institutional accounts, password updates must be initiated via your university identity portal.',
                    style: TextStyle(fontSize: 13, color: authMuted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!verified) ...[
              Form(
                key: _emailForm,
                child: AuthField(
                  label: 'Registered Academic / Work Email',
                  controller: _email,
                  hint: 'alex.rivera@cs.stanford.edu',
                  email: true,
                  validator: AuthValidators.email,
                  prefix: const FigmaIcon('forgot_imgContainer3'),
                  enabled: !_model.busy,
                  onChanged: (_) => setState(() => _sentEmail = null),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const FigmaIcon('forgot_imgContainer4'),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Recovery code sent to your inbox.', style: mono(10))),
                ],
              ),
              const SizedBox(height: 16),
              AuthButton(
                label: 'Send Reset Token',
                onPressed: _resendSeconds > 0 ? null : _send,
                busy: _model.busy,
                trailing: const FigmaIcon('forgot_imgContainer5'),
              ),
              const SizedBox(height: 8),
              AuthButton(
                label: 'Back to Sign In',
                secondary: true,
                leading: const FigmaIcon('forgot_imgContainer6'),
                onPressed: _model.busy ? null : _back,
              ),
              AuthFeedback(_model),
              const SizedBox(height: 24),
              AuthCard(
                padding: 16,
                background: authPanel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FigmaIcon('forgot_imgContainer7'),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Enter 6-Digit Code',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text('OTP', style: mono()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _sentEmail == null
                          ? 'Request a recovery email above, then enter the code here.'
                          : 'Check $_sentEmail and enter the 6-digit numeric token below.',
                      style: const TextStyle(fontSize: 13, color: authMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    CodeInput(onChanged: (value) => _code = value, enabled: _sentEmail != null && !_model.busy),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          _resendSeconds > 0 ? 'Resend available in ${_resendSeconds}s' : 'You can request a new code.',
                          style: mono(10),
                        ),
                        TextButton(
                          onPressed: _model.busy || _sentEmail == null ? null : _verify,
                          child: Text('Verify Token', style: mono().copyWith(color: authInk)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              AuthCard(
                padding: 16,
                child: Form(
                  key: _passwordForm,
                  child: Column(
                    children: [
                      AuthField(
                        label: 'New Password',
                        controller: _password,
                        password: true,
                        visible: _visible,
                        validator: AuthValidators.password,
                        enabled: !_model.busy,
                        onToggle: () => setState(() => _visible = !_visible),
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: 'Confirm New Password',
                        controller: _confirm,
                        password: true,
                        visible: _visible,
                        enabled: !_model.busy,
                        onToggle: () => setState(() => _visible = !_visible),
                        validator: (value) => value == _password.text ? null : 'Passwords do not match.',
                      ),
                      const SizedBox(height: 16),
                      AuthButton(label: 'Save New Password', onPressed: _updatePassword, busy: _model.busy),
                      AuthFeedback(_model),
                      TextButton(onPressed: _model.busy ? null : _back, child: const Text('Cancel recovery')),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AuthCard(
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RECOVERY STEPS', style: mono().copyWith(letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('Email → verify token → update password', style: mono(10)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Need assistance? Contact your course administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: authMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text('AlgoLens • Account Recovery', style: mono(10)),
          ],
        ),
      );
    },
  );
}
