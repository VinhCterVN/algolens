import 'package:algolens/core/theme/app_motion.dart';
import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_repository_provider.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_form_view_model.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_validators.dart';
import 'package:algolens/features/authentication/presentation/widgets/auth_stage_transition.dart';
import 'package:algolens/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController();

  AuthFormViewModel get _model => ref.read(authFormProvider(AuthFormId.register).notifier);

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  bool _visible = false, _educator = false, _accepted = false;
  String _experience = 'beginner', _code = '';
  String? _confirmationEmail;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (!_accepted) {
      _model.showError('Please read and accept the academic guidelines.');
      return;
    }
    final email = _email.text.trim();
    bool signedIn = false;
    final success = await _model.run(() async {
      signedIn = await _repository.register(
        name: _name.text,
        email: email,
        password: _password.text,
        requestedRole: _educator ? 'professor' : 'learner',
        experience: _experience,
      );
    });
    if (success && !signedIn && mounted) {
      _password.clear();
      setState(() => _confirmationEmail = email);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authFormProvider(AuthFormId.register));
    return AuthScaffold(
      title: 'Register Account',
      topPadding: 0,
      assetPrefix: 'register',
      backAsset: 'imgContainer11',
      userAsset: 'imgContainer12',
      onBack: () => context.go('/login'),
      child: AuthCard(
        child: AuthStageTransition(
          stage: _confirmationEmail == null ? 'registration' : 'confirmation',
          child: _confirmationEmail == null ? _registrationForm(context) : _confirmation(context),
        ),
      ),
    );
  }

  Widget _registrationForm(BuildContext context) {
    final rules = AuthValidators.passwordRules(_password.text);
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  child: Text('λ', style: mono(13).copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text('CREATE ACCOUNT', style: mono(10)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Create your AlgoLens Account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.65, height: 1.23),
            ),
            const SizedBox(height: 4),
            const Text(
              'Join students and researchers visualizing data structures in real-time.',
              style: TextStyle(color: authMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            const StatusStrip(label: 'Learning Environment', value: 'Interactive'),
            const SizedBox(height: 24),
            Text('ACADEMIC ROLE', style: mono(10)),
            const SizedBox(height: 4),
            _role(
              false,
              'Student / Learner',
              'Access interactive sandbox & step-through lessons.',
              'imgContainer',
              'imgContainer1',
            ),
            const SizedBox(height: 8),
            _role(
              true,
              'Professor / TA',
              'Course creation & classroom learning insights.',
              'imgContainer2',
              'imgContainer3',
            ),
            if (_educator) ...[
              const SizedBox(height: 8),
              const Text(
                'All new accounts start as learners. An administrator approves educator access.',
                style: TextStyle(fontSize: 12, color: authMuted),
              ),
            ],
            const SizedBox(height: 24),
            AuthField(
              label: 'FULL NAME',
              controller: _name,
              hint: 'Alex Rivera',
              validator: AuthValidators.name,
              enabled: !_model.busy,
              suffix: const FigmaIcon('register_imgContainer4'),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'ACADEMIC / UNIVERSITY EMAIL',
              controller: _email,
              hint: 'alex.rivera@university.edu',
              email: true,
              validator: AuthValidators.email,
              enabled: !_model.busy,
              suffix: const FigmaIcon('register_imgContainer5'),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'MASTER CIPHER / PASSWORD',
              controller: _password,
              hint: '••••••••••••',
              password: true,
              visible: _visible,
              validator: AuthValidators.password,
              enabled: !_model.busy,
              suffix: const FigmaIcon('register_imgContainer8'),
              onToggle: () => setState(() => _visible = !_visible),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(6)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const FigmaIcon('register_imgContainer6'),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Invariant Tracker', style: mono(10).copyWith(color: authInk)),
                      ),
                      Text('${rules.where((r) => r).length} / 3 Valid', style: mono(10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (rules[i])
                            const Icon(Icons.check, size: 10.5)
                          else
                            const FigmaIcon('register_imgContainer7'),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ['Min 8 characters', 'Includes numerical digit', 'Special character or symbol'][i],
                              style: mono(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('INITIAL COMPUTATIONAL RIGOR', style: mono(10)),
            const SizedBox(height: 4),
            for (final level in ['beginner', 'intermediate', 'advanced'])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: _model.busy ? null : () => setState(() => _experience = level),
                  child: Semantics(
                    selected: _experience == level,
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: _experience == level ? Colors.black : authMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(switch (level) {
                              'beginner' => 'Beginner (CS 101)',
                              'intermediate' => 'Intermediate (Data Structures)',
                              _ => 'Advanced (Competitive / Research)',
                            }, style: mono(10)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: Text(switch (level) {
                              'beginner' => 'O(N) focus',
                              'intermediate' => 'Trees & Heaps',
                              _ => 'Dynamic Prog',
                            }, style: mono(10)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SessionCheckbox(
              value: _accepted,
              onChanged: _model.busy ? null : (value) => setState(() => _accepted = value),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('I agree to the ', style: TextStyle(fontSize: 12, color: authMuted)),
                  InkWell(
                    onTap: () => _showGuidelines(context),
                    child: const Text(
                      'Academic Honor Code',
                      style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                  const Text(' and AlgoLens account guidelines.', style: TextStyle(fontSize: 12, color: authMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AuthButton(
              label: 'Initialize Account',
              onPressed: _register,
              busy: _model.busy,
              trailing: const FigmaIcon('register_imgContainer9'),
            ),
            AuthFeedback(ref.watch(authFormProvider(AuthFormId.register))),
            const SizedBox(height: 8),
            AuthButton(
              label: 'Quick Sign Up with GitHub',
              secondary: true,
              leading: const FigmaIcon('register_imgSvg'),
              onPressed: _model.busy
                  ? null
                  : () {
                      if (!_accepted) {
                        _model.showError('Please read and accept the academic guidelines.');
                        return;
                      }
                      _model.run(() => _repository.signInWithProvider(AuthProvider.github));
                    },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const FigmaIcon('register_imgContainer10'),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Learning Environment', style: mono(10).copyWith(color: authInk)),
                        Text('Step-through algorithms', style: mono(10)),
                      ],
                    ),
                  ),
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.circle, size: 6, color: i == 0 ? authInk : authMuted.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?', style: TextStyle(fontSize: 13, color: authMuted)),
                TextButton(
                  onPressed: _model.busy ? null : () => context.go('/login'),
                  child: const Text('Sign In', style: TextStyle(decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _role(bool educator, String title, String subtitle, String icon, String radio) {
    final selected = _educator == educator;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: _model.busy ? null : () => setState(() => _educator = educator),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: selected ? Colors.black : authPanel, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FigmaIcon('register_$icon', color: selected ? Colors.white : authMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? Colors.white : authInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FigmaIcon('register_$radio', color: selected ? Colors.white : authMuted),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: selected ? Colors.white70 : authMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmation(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Confirm your email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Text(
        'Check $_confirmationEmail for a confirmation link or 6-digit code. Once confirmed, your workspace will open.',
        style: const TextStyle(color: authMuted, height: 1.5),
      ),
      const SizedBox(height: 24),
      CodeInput(onChanged: (value) => _code = value, enabled: !_model.busy),
      const SizedBox(height: 16),
      AuthButton(
        label: 'Verify Email',
        busy: _model.busy,
        onPressed: () {
          final error = AuthValidators.code(_code);
          if (error != null) {
            _model.showError(error);
            return;
          }
          _model.run(() => _repository.verifyEmail(_confirmationEmail!, _code));
        },
      ),
      AuthFeedback(ref.watch(authFormProvider(AuthFormId.register))),
      TextButton(
        onPressed: _model.busy
            ? null
            : () => _model.run(
                () => _repository.resendConfirmation(_confirmationEmail!),
                successMessage: 'If confirmation is needed, a new email has been sent.',
              ),
        child: const Text('Resend confirmation email'),
      ),
      TextButton(onPressed: _model.busy ? null : () => context.go('/login'), child: const Text('Back to Sign In')),
    ],
  );

  void _showGuidelines(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Academic Honor Code'),
      content: const Text(
        'Use AlgoLens to understand concepts and practice honestly. Do not submit another learner’s work as your own. Keep discussions respectful and protect your account credentials. Educator permissions require administrator approval.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
