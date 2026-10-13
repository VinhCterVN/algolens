import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Override once at the application boundary with the configured repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) => UnconfiguredAuthRepository());
