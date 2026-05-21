/// Enumeration of all error codes that can be reported by the VIES package.
///
/// Codes are split between client-side problems (input shape, parsing) and
/// server-side problems (network, VIES SOAP faults). The textual message
/// associated with each code is intentionally end-user friendly — see
/// [ViesErrorCode.message].
enum ViesErrorCode {
  /// The supplied country code is unknown or the VAT number is empty.
  invalidInput('INVALID_INPUT',
      'The provided country code is invalid or the VAT number is empty.'),

  /// The VIES service itself is down.
  serviceUnavailable('SERVICE_UNAVAILABLE',
      'The VIES VAT service is unavailable, please try again later.'),

  /// The member-state database queried by VIES is down.
  msUnavailable('MS_UNAVAILABLE',
      'The VAT database of the requested member country is unavailable, '
          'please try again later.'),

  /// The member-state database is rate-limiting us.
  msMaxConcurrentReq('MS_MAX_CONCURRENT_REQ',
      'The VAT database of the requested member country has had too many '
          'requests, please try again later.'),

  /// The HTTP request timed out.
  timeout('TIMEOUT',
      'The request to the VAT database has timed out, please try again later.'),

  /// No network connectivity.
  socketException('SOCKET_EXCEPTION',
      'The service cannot process your request, internet disconnected. '
          'Please check your internet connection and try again later.'),

  /// VIES is overloaded.
  serverBusy('SERVER_BUSY',
      'The service cannot process your request, please try again later.'),

  /// Generic server/transport failure not otherwise classified.
  serverDisconnected('SERVER_DISCONNECTED',
      'The service cannot process your request, service disconnected. '
          'Please try again later.'),

  /// The requester information attached to the SOAP call is invalid.
  invalidRequesterInfo('INVALID_REQUESTER_INFO',
      'The requester info is invalid.'),

  /// The XML body returned by VIES could not be parsed.
  parsingError('PARSING_ERROR',
      'Failed to parse VAT validation info from the VIES response.'),

  /// The VAT number is syntactically or semantically invalid.
  invalidVatNumber('INVALID_VAT_NUMBER',
      'Your VAT number is invalid. Please check it and try again.'),

  /// The SOAP envelope contained a `<Fault>` element.
  soapFault('SOAP_FAULT', 'The VIES response contained a SOAP fault.'),

  /// Anything that does not fit another code.
  unknown('UNKNOWN', 'Unknown error.');

  const ViesErrorCode(this.wireName, this.message);

  /// Stable string identifier — safe to log, compare, persist or send over
  /// the wire. Matches the historical string codes from v1.x for forward
  /// compatibility.
  final String wireName;

  /// Human-readable, end-user friendly message in English.
  final String message;

  /// Lookup an error code by its [wireName]. Returns [unknown] if no match.
  static ViesErrorCode fromWireName(String? name) {
    if (name == null) return unknown;
    for (final code in values) {
      if (code.wireName == name) return code;
    }
    return unknown;
  }

  /// `true` when this code corresponds to a transient failure that may
  /// succeed if the same request is retried after a short backoff.
  bool get isRetryable => _retryableCodes.contains(this);
}

const Set<ViesErrorCode> _retryableCodes = {
  ViesErrorCode.msUnavailable,
  ViesErrorCode.msMaxConcurrentReq,
  ViesErrorCode.serviceUnavailable,
  ViesErrorCode.serverBusy,
  ViesErrorCode.timeout,
};
