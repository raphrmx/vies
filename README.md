[![VIES](https://ec.europa.eu/taxation_customs/vies/assets/images/ecl/ec/logo/logo-ec--fr.svg)](https://ec.europa.eu/taxation_customs/vies/technicalInformation.html)

<a alt="ComApps Logo" href="https://comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/wp-content/uploads/2026/09/CompleteLogoHorizontalMini.png" style="margin: 15px"></a>

# VIES (VAT Validation)

A Dart client for the EU [VIES `checkVat` SOAP service](https://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl).
Validates a VAT number and, when valid, returns the registered business
information (legal name, address) published by the member state.

[![Pub Version](https://img.shields.io/pub/v/vies?color=blue)](https://pub.dev/packages/vies)
![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-purple)
[![License](https://img.shields.io/badge/Licence-MIT-blue)](/LICENSE)
![Maintenance](https://img.shields.io/badge/Maintained-yes-success)
![Null Safety](https://img.shields.io/badge/Null_Safety-passing-success)
![Platforms](https://img.shields.io/badge/Platforms-Android,_iOS,_macOS,_Windows,_Linux,_Web-22375C.svg)

## Install

```sh
dart pub add vies      # Dart
flutter pub add vies   # Flutter
```

## Usage

```dart
import 'package:vies/vies.dart';

Future<void> main() async {
  try {
    final response = await ViesProvider.validateVat(
      countryCode: 'BE',
      vatNumber: '1000341796',
      timeout: const Duration(seconds: 15),
      retries: 2, // transient VIES faults are retried with backoff
    );
    print('Valid VAT for ${response.name}');
    print('Address: ${response.address}');
  } on ViesClientError catch (e) {
    // Invalid VAT, parsing errors, INVALID_INPUT faults ...
    print('Client error: ${e.code.wireName} — ${e.message}');
  } on ViesServerError catch (e) {
    // Network, timeout, VIES outage ...
    print('Server error: ${e.code.wireName} — ${e.message}');
  }
}
```

### Validation levels

```dart
// Offline regex check only (no network call):
await ViesProvider.validateVat(
  countryCode: 'FR',
  vatNumber: '64443061841',
  validationLevel: ValidationLevel.regex,
);

// Skip the regex pre-check, hit VIES directly:
await ViesProvider.validateVat(
  countryCode: 'FR',
  vatNumber: '64443061841',
  validationLevel: ValidationLevel.vies,
);

// Default: regex first, then VIES (saves a network round-trip on bad input):
await ViesProvider.validateVat(
  countryCode: 'FR',
  vatNumber: '64443061841',
  // validationLevel: ValidationLevel.all,
);
```

A regex-only result is not a validation. `source` says which check answered,
so a shape check is never recorded as a confirmation from a member state:

```dart
final response = await ViesProvider.validateVat(
  countryCode: 'FR',
  vatNumber: '64443061841',
  validationLevel: ValidationLevel.regex,
);
response.valid;  // true
response.source; // ValidationSource.regex, nobody confirmed anything
```

### Offline shape check

`VatShape` answers without a network call. `RegexType.eu` applies the format
published by each member state, `RegexType.world` a single permissive shape:

```dart
VatShape.isValid('NL123456789b01', RegexType.eu); // true, case-insensitive
VatShape.isValid('RO99908', RegexType.eu);        // true, RO is 2 to 10 digits
VatShape.isValid('DE12345', RegexType.eu);        // false, DE is 9 digits

VatShape.normalize(' 1234 5678-9b01 '); // 123456789B01
VatShape.supportedCountryCodes;         // the prefixes RegexType.eu knows
```

### Reusing an HTTP client

For batch validation, inject a shared `http.Client` to enable connection
pooling:

```dart
final client = http.Client();
try {
  for (final vat in batch) {
    await ViesProvider.validateVat(
      countryCode: vat.country,
      vatNumber: vat.number,
      client: client,
    );
  }
} finally {
  client.close();
}
```

`timeout` bounds one attempt, not the whole call. With `retries: 2` a call can
take up to three times the timeout plus the backoff, which is capped at
`maxRetryBackoff`.

### Test endpoint

`serviceUrl` selects the endpoint. The VIES test service answers
deterministically from the VAT number tail, which is useful in integration
tests that must not touch the real database:

```dart
await ViesProvider.validateVat(
  countryCode: 'BE',
  vatNumber: '100',
  serviceUrl: viesTestServiceUrl,
);
```

### Country prefixes

VIES uses ISO 3166-1 alpha-2 codes, with two exceptions:
* **`EL`** for Greece (instead of `GR`).
* **`XI`** for Northern Ireland (post-Brexit).

## Error codes

| `ViesErrorCode` value | `wireName` | Type | When |
| --- | --- | --- | --- |
| `invalidInput` | `INVALID_INPUT` | client | Country code unknown / VAT number empty |
| `invalidVatNumber` | `INVALID_VAT_NUMBER` | client | Failed regex or VIES `valid=false` |
| `parsingError` | `PARSING_ERROR` | client | Could not parse the SOAP body |
| `soapFault` | `SOAP_FAULT` | client | Other SOAP fault |
| `invalidRequesterInfo` | `INVALID_REQUESTER_INFO` | client | VIES rejected the requester block |
| `timeout` | `TIMEOUT` | server | Request timed out (retryable) |
| `socketException` | `SOCKET_EXCEPTION` | server | No internet connection |
| `serviceUnavailable` | `SERVICE_UNAVAILABLE` | server | VIES is down (retryable) |
| `msUnavailable` | `MS_UNAVAILABLE` | server | Member-state DB is down (retryable) |
| `msMaxConcurrentReq` | `MS_MAX_CONCURRENT_REQ` | server | Member-state DB rate-limited (retryable) |
| `serverBusy` | `SERVER_BUSY` | server | VIES is overloaded (retryable) |
| `serverDisconnected` | `SERVER_DISCONNECTED` | server | Generic transport failure |
| `unknown` | `UNKNOWN` | server | Anything else |

## Dependencies

- [http](https://pub.dev/packages/http)

## License

MIT - see [LICENSE](LICENSE).
