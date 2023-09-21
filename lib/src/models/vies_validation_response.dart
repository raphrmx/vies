///
/// Vies success response model
///
class ViesValidationResponse {
  final String countryCode;
  final String vatNumber;
  final String requestDate;
  final bool valid;
  final String? name;
  final String? address;

  const ViesValidationResponse({
    required this.countryCode,
    required this.vatNumber,
    required this.requestDate,
    required this.valid,
    this.name,
    this.address,
  });

  @override
  String toString() => toJson().entries.map((e) => '${e.key} = ${e.value}').join('\n');

  Map<String, dynamic> toJson() => {
        "countryCode": countryCode,
        "vatNumber": vatNumber,
        "requestDate": requestDate,
        "valid": valid,
        "name": name,
        "address": address,
      };
}
