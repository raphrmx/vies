/// Which VAT-number regular expression to apply when [ValidationLevel.regex]
/// or [ValidationLevel.all] is requested.
enum RegexType {
  /// Strict: the country prefix must be one VIES knows (EU member states plus
  /// `EL` for Greece and `XI` for Northern Ireland) and the number must match
  /// that country's published format.
  eu,

  /// Lenient: any 2-4 uppercase letter prefix followed by an alphanumeric
  /// VAT number. Useful when validating non-EU entities the same way.
  world,
}

/// Where the answer carried by a `ViesValidationResponse` comes from.
///
/// A regex-only result says the number is well formed, nothing more. Only
/// [ValidationSource.vies] means a member state confirmed the registration,
/// which is the distinction that matters when the result is recorded for
/// fiscal purposes.
enum ValidationSource {
  /// The VIES service answered.
  vies,

  /// Only the offline shape check ran. See [ValidationLevel.regex].
  regex,
}

/// Granularity of validation performed by [ViesProvider.validateVat].
enum ValidationLevel {
  /// Only the offline regex check is performed - no network call.
  regex,

  /// Only the VIES SOAP call is performed - no offline regex pre-check.
  vies,

  /// Both checks are performed; the regex acts as a fast-fail before the
  /// network call. **Default.**
  all,
}
