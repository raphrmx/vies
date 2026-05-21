import 'package:vies/src/enums.dart';

/// Offline syntactic validation of VAT numbers.
///
/// The package ships two regexes — see [VatShape.isValid] — so callers can
/// trade strictness (`RegexType.eu`) for tolerance (`RegexType.world`).
abstract final class VatShape {
  VatShape._();

  /// VAT prefixes officially used by VIES: EU member states plus the
  /// domain-specific `EL` (Greece) and `XI` (Northern Ireland) codes.
  static final RegExp _euVatRegex = RegExp(
    '^(AT|BE|BG|HR|CY|CZ|DE|DK|EE|EL|ES|FI|FR|GB|HU|IE|IT|LT|LU|LV|MT|NL|PL|PT|RO|SE|SI|SK|XI)'
    '[0-9A-Za-z+*.]{8,12}\$',
  );

  /// Lenient regex: any 2–4 uppercase letters followed by 8–20 alphanumeric
  /// characters.
  static final RegExp _worldVatRegex = RegExp('^[A-Z]{2,4}[A-Z0-9]{8,20}\$');

  /// Spaces and hyphens commonly inserted by users for readability.
  static final RegExp _cleanupRegex = RegExp(r'[\s-]+');

  /// Remove user-friendly separators (spaces, hyphens) from a VAT number.
  static String normalize(String vatNumber) =>
      vatNumber.replaceAll(_cleanupRegex, '');

  /// `true` when [fullVatNumber] (country prefix concatenated with the VAT
  /// digits) matches the selected regex.
  static bool isValid(String fullVatNumber, RegexType regexType) {
    final cleaned = normalize(fullVatNumber);
    return (regexType == RegexType.eu ? _euVatRegex : _worldVatRegex)
        .hasMatch(cleaned);
  }
}
