import 'package:vies/src/enums.dart';

/// Result of a successful VAT validation, either from the VIES SOAP service
/// or from a local shape check. [source] says which of the two answered.
///
/// Notes on the date format:
///   * When the response comes from VIES, [requestDate] is the raw value
///     returned in the SOAP envelope - typically `YYYY-MM-DD+HH:MM` (date
///     plus offset, no time component).
///   * When the response is local (regex-only mode), [requestDate] is an ISO
///     8601 UTC timestamp produced by the package.
///
/// Use [requestDateTime] to obtain a best-effort [DateTime] regardless of the
/// underlying format.
class ViesValidationResponse {
  /// Creates a validation result.
  ///
  /// ---
  ///
  /// ### Parameters:
  /// - [countryCode]: two-letter prefix of the validated number.
  /// - [vatNumber]: the number without its country prefix.
  /// - [requestDate]: raw date as returned by VIES, or an ISO 8601 timestamp
  ///   when the answer was produced locally. See [requestDateTime].
  /// - [valid]: whether the number is registered.
  /// - [name]: registered business name, when the member state publishes it.
  /// - [address]: registered address, when the member state publishes it.
  /// - [source]: which check produced this result. Defaults to
  ///   [ValidationSource.vies].
  const ViesValidationResponse({
    required this.countryCode,
    required this.vatNumber,
    required this.requestDate,
    required this.valid,
    this.name,
    this.address,
    this.source = ValidationSource.vies,
  });

  /// Build a response from a decoded JSON map (e.g. the output of [toJson]).
  factory ViesValidationResponse.fromJson(Map<String, Object?> json) =>
      ViesValidationResponse(
        countryCode: json['countryCode']! as String,
        vatNumber: json['vatNumber']! as String,
        requestDate: json['requestDate']! as String,
        valid: json['valid']! as bool,
        name: json['name'] as String?,
        address: json['address'] as String?,
        source: ValidationSource.values.firstWhere(
          (value) => value.name == json['source'],
          orElse: () => ValidationSource.vies,
        ),
      );

  /// Two-letter country code reported by VIES. For Greece this is `EL`, for
  /// Northern Ireland it may be `XI`.
  final String countryCode;

  /// VAT number, without the country prefix.
  final String vatNumber;

  /// Raw `requestDate` as returned by VIES (or an ISO 8601 timestamp in
  /// regex-only mode). See class doc for format details.
  final String requestDate;

  /// `true` when VIES confirmed the VAT number is currently valid.
  final bool valid;

  /// Legal name of the business, when disclosed by the member state.
  final String? name;

  /// Registered address of the business, when disclosed by the member state.
  final String? address;

  /// Which check produced this result.
  ///
  /// [ValidationSource.regex] means only the offline shape was checked, so
  /// [valid] carries no confirmation from any member state.
  final ValidationSource source;

  /// Best-effort [DateTime] parse of [requestDate]. Returns `null` when the
  /// value cannot be parsed.
  DateTime? get requestDateTime {
    final iso = DateTime.tryParse(requestDate);
    if (iso != null) return iso;
    // VIES format: 2026-05-21+02:00 -> fall back to date-only by trimming the
    // offset, since DateTime.parse rejects a date with offset and no time.
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(requestDate);
    if (match != null) return DateTime.tryParse(match.group(1)!);
    return null;
  }

  /// Return a copy of this response with the given fields overridden.
  ViesValidationResponse copyWith({
    String? countryCode,
    String? vatNumber,
    String? requestDate,
    bool? valid,
    String? name,
    String? address,
    ValidationSource? source,
  }) => ViesValidationResponse(
    countryCode: countryCode ?? this.countryCode,
    vatNumber: vatNumber ?? this.vatNumber,
    requestDate: requestDate ?? this.requestDate,
    valid: valid ?? this.valid,
    name: name ?? this.name,
    address: address ?? this.address,
    source: source ?? this.source,
  );

  /// JSON representation, round-trippable through
  /// [ViesValidationResponse.fromJson].
  Map<String, Object?> toJson() => {
    'countryCode': countryCode,
    'vatNumber': vatNumber,
    'requestDate': requestDate,
    'valid': valid,
    'name': name,
    'address': address,
    'source': source.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViesValidationResponse &&
          other.countryCode == countryCode &&
          other.vatNumber == vatNumber &&
          other.requestDate == requestDate &&
          other.valid == valid &&
          other.name == name &&
          other.address == address &&
          other.source == source;

  @override
  int get hashCode => Object.hash(
    countryCode,
    vatNumber,
    requestDate,
    valid,
    name,
    address,
    source,
  );

  @override
  String toString() =>
      'ViesValidationResponse('
      'countryCode: $countryCode, '
      'vatNumber: $vatNumber, '
      'requestDate: $requestDate, '
      'valid: $valid, '
      'name: $name, '
      'address: $address, '
      'source: ${source.name})';
}
