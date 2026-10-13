import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_repository_provider.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_form_view_model.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_validators.dart';
import 'package:algolens/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  AuthFormViewModel get _model => ref.read(authFormProvider(AuthFormId.signIn).notifier);

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  bool _visible = false, _remember = true, _educator = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_form.currentState!.validate()) {
      await _model.run(() => _repository.signIn(_email.text, _password.text, remember: _remember));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authFormProvider(AuthFormId.signIn));
    return AuthScaffold(
      title: 'Sign In',
      assetPrefix: 'sign_in',
      backAsset: 'imgContainer6',
      userAsset: 'imgContainer7',
      child: Column(
        children: [
          const _SignInBrand(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: authPanel, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                for (final educator in [false, true])
                  Expanded(
                    child: TextButton(
                      onPressed: _model.busy ? null : () => setState(() => _educator = educator),
                      style: TextButton.styleFrom(
                        backgroundColor: _educator == educator ? Colors.black : Colors.transparent,
                        foregroundColor: _educator == educator ? Colors.white : authMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FigmaIcon(
                            educator ? 'sign_in_imgContainer1' : 'sign_in_imgContainer',
                            color: _educator == educator ? Colors.white : authMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            educator ? 'Educator' : 'Learner',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthCard(
            shadow: true,
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthField(
                      label: 'Institutional or Personal Email',
                      controller: _email,
                      hint: _educator ? 'professor@university.edu' : 'alex.rivera@cs.stanford.edu',
                      email: true,
                      validator: AuthValidators.email,
                      enabled: !_model.busy,
                      prefix: const FigmaIcon('sign_in_imgIcon'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _educator
                          ? 'Educator access is approved by an administrator.'
                          : 'Use your academic or personal email.',
                      style: mono(),
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      label: 'Password',
                      controller: _password,
                      password: true,
                      visible: _visible,
                      hint: '••••••••••••',
                      enabled: !_model.busy,
                      validator: AuthValidators.requiredPassword,
                      prefix: const FigmaIcon('sign_in_imgIcon1'),
                      suffix: FigmaIcon('sign_in_imgContainer2', color: _visible ? Colors.black : authMuted),
                      onToggle: () => setState(() => _visible = !_visible),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _signIn(),
                      trailing: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: _model.busy ? null : () => context.go('/forgot-password'),
                        child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i < AuthValidators.passwordRules(_password.text).where((r) => r).length
                                          ? Colors.black
                                          : const Color(0xFFE2E2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(_password.text.isEmpty ? 'PASSWORD' : 'STRENGTH', style: mono(10)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SessionCheckbox(
                      value: _remember,
                      onChanged: _model.busy ? null : (value) => setState(() => _remember = value),
                      checkAsset: 'sign_in_imgContainer3',
                      child: const Text('Remember workstation for 30 days', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    AuthButton(
                      label: 'Sign In to Workspace',
                      onPressed: _signIn,
                      busy: _model.busy,
                      trailing: const Text('→'),
                    ),
                    AuthFeedback(ref.watch(authFormProvider(AuthFormId.signIn))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E2E2))),
              const SizedBox(width: 16),
              Text('OR CONTINUE WITH', style: mono(11).copyWith(letterSpacing: 1.1)),
              const SizedBox(width: 16),
              const Expanded(child: Divider(color: Color(0xFFE2E2E2))),
            ],
          ),
          const SizedBox(height: 24),
          _provider(
            'Continue with GitHub',
            'sign_in_imgSvgMonochromaticGitHubOctocatVector',
            AuthProvider.github,
            'OAuth',
          ),
          const SizedBox(height: 8),
          _provider(
            'Continue with Google / Edu Domain',
            'sign_in_imgSvgCleanMonochromaticGoogleIcon',
            AuthProvider.google,
            'Google',
          ),
          const SizedBox(height: 24),
          AuthCard(
            padding: 16,
            background: authPanel,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  child: Text('O(n)', style: mono(12).copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('See Each Algorithm Step', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                        'Build your understanding, one lesson at a time.',
                        style: TextStyle(color: authMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const FigmaIcon('sign_in_imgContainer4'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              const Text("Don't have an account yet?", style: TextStyle(fontSize: 13)),
              TextButton(
                onPressed: _model.busy ? null : () => context.go('/register'),
                child: const Text('Register here', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FigmaIcon('sign_in_imgContainer5'),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'Your credentials are protected by Supabase Auth.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: authMuted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(4)),
            child: Text('AlgoLens • Interactive Learning Platform', style: mono(10)),
          ),
        ],
      ),
    );
  }

  Widget _provider(String label, String asset, AuthProvider provider, String tag) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _model.busy
          ? null
          : () => _model.run(() => _repository.signInWithProvider(provider, remember: _remember)),
      child: Row(
        children: [
          FigmaIcon(asset),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(tag, style: mono()),
        ],
      ),
    ),
  );
}

class _SignInBrand extends StatelessWidget {
  const _SignInBrand();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 68,
        height: 72,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: const FigmaIcon('sign_in_imgSvg'),
            ),
            Positioned(
              right: 0,
              top: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                child: Text('λ-01', style: mono(9).copyWith(color: Colors.white, letterSpacing: 0.9)),
              ),
            ),
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('AlgoLens', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.65)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(4)),
            child: Text('IDE', style: mono()),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        'See the Logic. Master the Algorithm.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.375),
      ),
      const SizedBox(height: 4),
      const Text(
        'Sign in to resume your algorithmic coursework and interactive simulations.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: authMuted, height: 1.4),
      ),
    ],
  );
}
