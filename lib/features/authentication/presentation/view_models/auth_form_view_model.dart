import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthFormId { signIn, register, recovery }

class AuthFormState {
  const AuthFormState({this.busy = false, this.error, this.message});

  final bool busy;
  final String? error;
  final String? message;
}

final authFormProvider = NotifierProvider.autoDispose.family<AuthFormViewModel, AuthFormState, AuthFormId>(
  AuthFormViewModel.new,
);

class AuthFormViewModel extends Notifier<AuthFormState> {
  AuthFormViewModel(this.form);

  final AuthFormId form;

  @override
  AuthFormState build() => const AuthFormState();

  bool get busy => state.busy;

  void showError(String message) {
    if (ref.mounted) state = AuthFormState(error: message);
  }

  Future<bool> run(Future<void> Function() action, {String? successMessage}) async {
    if (!ref.mounted || state.busy) return false;
    state = const AuthFormState(busy: true);
    try {
      await action();
      if (ref.mounted) state = AuthFormState(message: successMessage);
      return true;
    } on AuthFailure catch (failure) {
      if (ref.mounted) state = AuthFormState(error: failure.message);
      return false;
    } catch (_) {
      if (ref.mounted) state = const AuthFormState(error: 'Something went wrong. Please try again.');
      return false;
    }
  }
}
