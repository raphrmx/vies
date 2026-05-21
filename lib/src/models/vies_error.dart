import 'package:vies/src/error_code.dart';

/// Base class for every error raised by the `vies` package.
///
/// Implements [Exception] so it can be caught with `on Exception` and so it
/// participates correctly in Dart's error semantics (the previous v1.x
/// hierarchy extended [AssertionError], which is reserved for debug-mode
/// invariants).
///
/// Two concrete subtypes exist:
///   * [ViesClientError] — the request never reached VIES, or VIES returned
///     a logically negative answer (e.g. invalid VAT number).
///   * [ViesServerError] — VIES, the network, or the transport itself failed.
sealed class ViesError implements Exception {
  const ViesError({
    required this.code,
    String? message,
    this.viesResponse,
  }) : _message = message;

  /// Strongly-typed error code.
  final ViesErrorCode code;

  /// Raw text returned (or synthesised) for this error — typically the
  /// user-facing message.
  final String? viesResponse;

  final String? _message;

  /// Stable type discriminator used in JSON output.
  String get typeName;

  /// Effective message: the explicit one if supplied, otherwise the canonical
  /// message attached to [code].
  String get message => _message ?? code.message;

  /// JSON representation, suitable for logging or persistence.
  Map<String, Object?> toJson() => {
        'type': typeName,
        'code': code.wireName,
        'message': message,
        'viesResponse': viesResponse,
      };

  @override
  String toString() => '$typeName(${code.wireName}): $message';
}

/// Errors caused by the input or the parsed response (e.g. invalid VAT
/// number, malformed SOAP body).
final class ViesClientError extends ViesError {
  const ViesClientError({
    required super.code,
    super.message,
    super.viesResponse,
  });

  @override
  String get typeName => 'ViesClientError';
}

/// Errors caused by the transport or by VIES itself (timeouts, faults,
/// connectivity loss).
final class ViesServerError extends ViesError {
  const ViesServerError({
    required super.code,
    super.message,
    super.viesResponse,
  });

  @override
  String get typeName => 'ViesServerError';
}
