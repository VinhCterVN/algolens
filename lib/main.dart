import 'package:algolens/core/config/supabase_config.dart';
import 'package:algolens/core/routing/app_router.dart';
import 'package:algolens/core/theme/app_theme.dart';
import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_service.dart';
import 'package:algolens/features/authentication/data/auth_session_storage.dart';
import 'package:algolens/features/authentication/data/supabase_auth_repository.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.load();
  AuthRepository repository = UnconfiguredAuthRepository();
  if (SupabaseConfig.isConfigured) {
    SupabaseConfig.validate();
    final storage = AuthSessionStorage(projectHost: Uri.parse(SupabaseConfig.url).host);
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(localStorage: storage),
      debug: false,
    );
    repository = SupabaseAuthRepository(AuthService(Supabase.instance.client, storage));
  }
  runApp(MyApp(repository: repository));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository});

  final AuthRepository? repository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthSessionController _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository ?? UnconfiguredAuthRepository();
    _session = AuthSessionController(repository);
    _router = createAppRouter(repository, _session);
  }

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AlgoLens',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
