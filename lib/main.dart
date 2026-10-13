import 'package:algolens/core/config/supabase_config.dart';
import 'package:algolens/core/routing/app_router.dart';
import 'package:algolens/core/theme/app_theme.dart';
import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_repository_provider.dart';
import 'package:algolens/features/authentication/data/auth_service.dart';
import 'package:algolens/features/authentication/data/auth_session_storage.dart';
import 'package:algolens/features/authentication/data/supabase_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final AuthRepository? repository;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [if (repository != null) authRepositoryProvider.overrideWithValue(repository!)],
    child: const _AlgoLensApp(),
  );
}

class _AlgoLensApp extends ConsumerWidget {
  const _AlgoLensApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AlgoLens',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
