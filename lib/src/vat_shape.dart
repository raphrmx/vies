import 'package:vies/src/enums.dart';

/// Offline syntactic validation of VAT numbers.
///
/// Two strategies are available, selected by [RegexType]: a per-country table
/// of the formats the VIES member states publish (`RegexType.eu`), or a single
/// permissive shape for anything else (`RegexType.world`). See
/// [VatShape.isValid].
abstract final class VatShape {
  VatShape._();

  /// Shape of the number that follows each country prefix.
  ///
  /// Where a country kept more than one historical form, the entry is
  /// deliberately permissive: rejecting a registered number offline is worse
  /// than letting VIES answer.
  static final Map<String, RegExp> _countryFormats = {
    'AT': RegExp(r'^U[0-9]{8}$'),
    'BE': RegExp(r'^[0-9]{9,10}$'),
    'BG': RegExp(r'^[0-9]{9,10}$'),
    'CY': RegExp(r'^[0-9]{8}[A-Z]$'),
    'CZ': RegExp(r'^[0-9]{8,10}$'),
    'DE': RegExp(r'^[0-9]{9}$'),
    'DK': RegExp(r'^[0-9]{8}$'),
    'EE': RegExp(r'^[0-9]{9}$'),
    'EL': RegExp(r'^[0-9]{9}$'),
    'ES': RegExp(r'^[A-Z0-9][0-9]{7}[A-Z0-9]$'),
    'FI': RegExp(r'^[0-9]{8}$'),
    'FR': RegExp(r'^[A-Z0-9]{2}[0-9]{9}$'),
    'GB': RegExp(r'^([0-9]{9}|[0-9]{12}|(GD|HA)[0-9]{3})$'),
    'HR': RegExp(r'^[0-9]{11}$'),
    'HU': RegExp(r'^[0-9]{8}$'),
    'IE': RegExp(
      r'^([0-9]{7}[A-W]|[7-9][A-Z*+][0-9]{5}[A-W]|[0-9]{7}[A-W][AH])$',
    ),
    'IT': RegExp(r'^[0-9]{11}$'),
    'LT': RegExp(r'^([0-9]{9}|[0-9]{12})$'),
    'LU': RegExp(r'^[0-9]{8}$'),
    'LV': RegExp(r'^[0-9]{11}$'),
    'MT': RegExp(r'^[0-9]{8}$'),
    'NL': RegExp(r'^[0-9]{9}B[0-9]{2}$'),
    'PL': RegExp(r'^[0-9]{10}$'),
    'PT': RegExp(r'^[0-9]{9}$'),
    'RO': RegExp(r'^[0-9]{2,10}$'),
    'SE': RegExp(r'^[0-9]{12}$'),
    'SI': RegExp(r'^[0-9]{8}$'),
    'SK': RegExp(r'^[0-9]{10}$'),
    'XI': RegExp(r'^([0-9]{9}|[0-9]{12}|(GD|HA)[0-9]{3})$'),
  };

  /// Lenient shape: two to four letters of prefix followed by an alphanumeric
  /// number, for entities outside the VIES member states.
  static final RegExp _worldVatRegex = RegExp(r'^[A-Z]{2,4}[A-Z0-9]{8,20}$');

  /// Separators users insert for readability, plus the dots some countries
  /// print inside the number.
  static final RegExp _cleanupRegex = RegExp(r'[\s.\-]+');

  /// Country prefix at the head of a full VAT number.
  static final RegExp _prefixRegex = RegExp(r'^([A-Z]{2})(.+)$');

  /// Country prefixes the `RegexType.eu` strategy knows.
  static Iterable<String> get supportedCountryCodes => _countryFormats.keys;

  /// Strips the separators a user may have typed and upper-cases the result.
  ///
  /// VAT numbers are case-insensitive and canonically upper case, and the
  /// letters they contain (the Dutch `B`, the Irish check letter) have to
  /// match the validation patterns whichever case they were typed in.
  ///
  /// ---
  ///
  /// ### Parameters:
  /// - [vatNumber]: the raw value, with or without separators.
  ///
  /// ### Returns:
  /// The normalised number.
  ///
  /// ### Example:
  /// ```dart
  /// VatShape.normalize(' 1234 5678-9b01 '); // 123456789B01
  /// ```
  static String normalize(String vatNumber) =>
      vatNumber.replaceAll(_cleanupRegex, '').toUpperCase();

  /// Whether [fullVatNumber] has a plausible shape.
  ///
  /// [fullVatNumber] is the country prefix concatenated with the number. It
  /// goes through [normalize] first, so separators and lower case are
  /// accepted.
  ///
  /// With [RegexType.eu] the prefix must be one VIES knows and the number must
  /// match that country's format. With [RegexType.world] a single permissive
  /// shape is applied instead.
  ///
  /// ---
  ///
  /// ### Parameters:
  /// - [fullVatNumber]: prefix and number, concatenated.
  /// - [regexType]: which strategy to apply.
  ///
  /// ### Returns:
  /// `true` when the shape is plausible. This says nothing about the number
  /// being registered, which only VIES can answer.
  ///
  /// ### Example:
  /// ```dart
  /// VatShape.isValid('NL123456789b01', RegexType.eu); // true
  /// VatShape.isValid('RO99908', RegexType.eu); // true
  /// ```
  static bool isValid(String fullVatNumber, RegexType regexType) {
    final cleaned = normalize(fullVatNumber);
    if (regexType == RegexType.world) return _worldVatRegex.hasMatch(cleaned);

    final match = _prefixRegex.firstMatch(cleaned);
    if (match == null) return false;

    final format = _countryFormats[match.group(1)];
    return format != null && format.hasMatch(match.group(2)!);
  }
}
