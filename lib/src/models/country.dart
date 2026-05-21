/// A country exposed by the package as a known VAT origin.
///
/// The list at [europeanCountries] (in `constants.dart`) is not strictly
/// limited to EU member states — it also contains a few neighbouring
/// territories that may appear in business directories. For *VIES* validity
/// the canonical list is the regex inside [ViesProvider].
class Country {
  const Country({required this.name, required this.code});

  /// English country name.
  final String name;

  /// ISO 3166-1 alpha-2 country code (uppercase), with two domain-specific
  /// exceptions used by VIES: `EL` (Greece) and `XI` (Northern Ireland).
  final String code;

  Map<String, String> toJson() => {'name': name, 'code': code};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && other.name == name && other.code == code;

  @override
  int get hashCode => Object.hash(name, code);

  @override
  String toString() => 'Country($code: $name)';
}
