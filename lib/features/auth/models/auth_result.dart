import 'user_model.dart';

/// A sealed class representing the outcome of an authentication attempt.
/// Using a sealed class ensures that we handle all possible outcomes.
sealed class AuthResult {}

/// Represents a successful authentication.
class AuthSuccess extends AuthResult {
  final String message;
  AuthSuccess({required this.message});
}

/// Represents a successful login, which includes a token.
class LoginSuccess extends AuthResult {
  final String message;
  final String token;
  final User user;
  LoginSuccess({
    required this.message,
    required this.token,
    required this.user,
  });
}

/// Represents a failed authentication.
class AuthFailure extends AuthResult {
  final String message;
  AuthFailure({required this.message});
}
