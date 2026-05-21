[![VIES](https://ec.europa.eu/taxation_customs/vies/assets/images/ecl/ec/logo/logo-ec--fr.svg)](https://ec.europa.eu/taxation_customs/vies/technicalInformation.html)

<a alt="ComApps Logo" href="https://comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/public/images/CompleteLogoHorizontalMini.png" height="45" style="margin: 15px"></a>

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
    // Invalid VAT, parsing errors, INVALID_INPUT faults …
    print('Client error: ${e.code.wireName} — ${e.message}');
  } on ViesServerError catch (e) {
    // Network, timeout, VIES outage …
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

MIT — see [LICENSE](LICENSE).
