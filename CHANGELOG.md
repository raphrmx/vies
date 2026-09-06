## 2.0.0

Major rewrite. **Breaking changes** - see migration notes below.

### Added
- `VatShape` is now public: `VatShape.isValid` and `VatShape.normalize` give
  an offline shape check without a network call, and
  `VatShape.supportedCountryCodes` lists the prefixes `RegexType.eu` knows.
- `ValidationSource` on `ViesValidationResponse`: `regex` marks a result that
  only passed the offline shape check, `vies` one a member state confirmed.
  A regex-only answer is no longer indistinguishable from a real validation.
- `serviceUrl:` parameter on `validateVat`, so `viesTestServiceUrl` can
  actually be reached. It was exported but unusable.
- `maxRetryBackoff` constant, capping the exponential backoff.
- `ViesErrorCode` enum replacing the previous string codes; each value
  carries a `wireName` (stable identifier) and a human-readable `message`.
- Sealed `ViesError` base class, implemented by `ViesClientError` and
  `ViesServerError` - both now `implements Exception` instead of extending
  `AssertionError`.
- `http.Client` injection via the new `client:` parameter - enables
  connection reuse and clean mocking in tests.
- Optional `retries:` parameter with exponential backoff for transient VIES
  faults (`MS_UNAVAILABLE`, `MS_MAX_CONCURRENT_REQ`, `SERVICE_UNAVAILABLE`,
  `SERVER_BUSY`, `TIMEOUT`).
- Strongly-typed `Country` class; `europeanCountries` is now
  `List<Country>`.
- `ViesValidationResponse`: value-based `==` / `hashCode`, `copyWith`,
  `fromJson`, and a `requestDateTime` helper that parses the VIES
  `date+offset` format.
- `ViesProvider.debugParseSoapResponse` for parsing tests without HTTP.
- Recognises Greek prefix `EL` and Northern Ireland prefix `XI` in the EU
  regex.
- XML escaping of inputs before they are placed in the SOAP body.

### Fixed
- An unreadable response body was reported as `INVALID_VAT_NUMBER` instead of
  `PARSING_ERROR`. An HTML error page served with a 200, or an empty body, told
  the caller their VAT number was invalid when it was not. The completeness
  check now runs before the `valid` flag is read.
- A VAT number typed in lower case was rejected offline: `normalize` stripped
  separators without upper-casing, while the default `RegexType.world` pattern
  requires upper case. Numbers ending in a letter, such as the Dutch `B01`,
  were the visible victims.
- `RegexType.eu` applied one shared `{8,12}` length to all 29 prefixes, which
  rejected registered numbers. Each member state now has its own format, so
  Romanian numbers (2 to 10 digits) validate.
- A malformed numeric character reference in a business name raised a raw
  `RangeError` through the documented `ViesError` contract. Such a reference is
  now left in place.
- The retry backoff had no ceiling, so a large `retries` produced unbounded
  waits. It is capped at `maxRetryBackoff`, and a negative `retries` counts
  as zero.
- Removed the `dart:io` import (used only for `SocketException`) which broke
  Flutter web compilation. Transport failures are now classified from
  `http.ClientException` and work on every platform, web included.
- Catch-all that previously swallowed `ViesClientError` from the parsing
  path and reported every failure as `SERVER_DISCONNECTED`.
- Typo in error code `SERVER_DICONNECTED` -> `SERVER_DISCONNECTED` (now
  exposed only via `ViesErrorCode.serverDisconnected.wireName`).
- Iceland country code corrected from `IC` to `IS`.
- Regex shape errors now raise `ViesClientError` (was `ViesServerError`).

### Changed
- `soapBodyTemplate` and `viesHeaders` are no longer exported: they describe
  how the request is built, not what the package offers.
- `timeout` is documented as bounding one attempt, not a whole call with
  retries.
- `ViesProvider` is now an `abstract final class` with a private constructor
  - no longer instantiable.
- Internal modules split out of the provider for clarity and testability:
  - `xml_codec.dart` - XML escape/unescape and tag extraction.
  - `vat_shape.dart` - offline VAT regex validation.
  - `soap_parser.dart` - SOAP body -> `ViesValidationResponse` decoding.
  The provider itself now only owns the public API, the HTTP call, and the
  retry loop.
- Pre-compiled all regular expressions (one-time cost per process).
- Cleaner SOAP body template using `{countryCode}` / `{vatNumber}` markers.
- HTTP headers no longer include `Host` / `Connection` (handled by the
  transport) and use a sensible `Content-Type`.
- Robust namespace handling - parser tolerates any prefix on SOAP and VIES
  elements and arbitrary attributes on tags.
- `requestDate` in regex-only mode is now a proper ISO 8601 UTC timestamp.
- Empty `name` / `address` values are normalised to `null`.

### Removed
- `html_unescape` dependency - replaced by an in-package XML entity decoder.
- `ViesProvider.classId` field (was test-only scaffolding).
- The standalone `viesErrors` map - error messages now live on
  `ViesErrorCode`.

### Migration from 1.x

```diff
- import 'package:vies/vies.dart';
- try {
-   final res = await ViesProvider.validateVat(
-     countryCode: 'BE',
-     vatNumber: '1000341796',
-   );
- } on ViesServerError catch (e) {
-   if (e.errorCode == 'SERVER_DICONNECTED') { ... }
- }

+ import 'package:vies/vies.dart';
+ try {
+   final res = await ViesProvider.validateVat(
+     countryCode: 'BE',
+     vatNumber: '1000341796',
+   );
+ } on ViesServerError catch (e) {
+   if (e.code == ViesErrorCode.serverDisconnected) { ... }
+ } on ViesClientError catch (e) {
+   // Invalid VAT, parsing errors, INVALID_INPUT faults ...
+ }
```

## 1.1.0

- Update package to dart ">=3.0.0 <4.0.0"
- Update all dependencies to latest versions
- Improvement of the response parser
- Add regex validation
- Add more tests

## 1.0.2

- Adapt to new vies SOAP response format

## 1.0.1

- Add github public repository and issue tracker

## 1.0.0+1

- Increase exceptions management
- Add more managed exceptions (SocketTimeout, TimeoutException)

## 1.0.0

- Add accessible constant country codes list
- Add accessible constant errors list
- Code refactoring

## 0.0.2

- Fix https envelope error ("Envelope" element, is not a valid SOAP version)

## 0.0.1+1

- Update lint

## 0.0.1

- Initial prerelease.
