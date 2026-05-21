/// Which VAT-number regular expression to apply when [ValidationLevel.regex]
/// or [ValidationLevel.all] is requested.
enum RegexType {
  /// Strict: only the country prefixes officially used by VIES are accepted
  /// (EU member states + `EL` for Greece + `XI` for Northern Ireland).
  eu,

  /// Lenient: any 2–4 uppercase letter prefix followed by an alphanumeric
  /// VAT number. Useful when validating non-EU entities the same way.
  world,
}

/// Granularity of validation performed by [ViesProvider.validateVat].
enum ValidationLevel {
  /// Only the offline regex check is performed — no network call.
  regex,

  /// Only the VIES SOAP call is performed — no offline regex pre-check.
  vies,

  /// Both checks are performed; the regex acts as a fast-fail before the
  /// network call. **Default.**
  all,
}
