import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, this.repository});

  final AuthRepository? repository;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: repository == null
          ? null
          : AppBar(
              title: const Text('Home'),
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    try {
                      await repository!.signOut();
                    } on AuthFailure catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/algolens_launcher.png',
                    width: 120,
                    height: 120,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text('AlgoLens', style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('See the Logic Behind Every Algorithm', style: textTheme.bodyLarge, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
