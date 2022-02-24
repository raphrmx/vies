///
/// Vies client error response model
///
class ViesClientError extends AssertionError {
  final String? viesResponse;
  final String? errorCode;

  ViesClientError({
    final String? message,
    this.viesResponse,
    this.errorCode,
  }) : super(message);

  @override
  String toString() =>
      toJson().entries.map((e) => '${e.key} = ${e.value}').join('\n');

  Map<String, dynamic> toJson() => {
        "errorCode": errorCode,
        "soapResponse": viesResponse,
        "message": message,
      };
}
