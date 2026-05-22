## 2.0.0

Major rewrite. **Breaking changes** — see migration notes below.

### Added
- `ViesErrorCode` enum replacing the previous string codes; each value
  carries a `wireName` (stable identifier) and a human-readable `message`.
- Sealed `ViesError` base class, implemented by `ViesClientError` and
  `ViesServerError` — both now `implements Exception` instead of extending
  `AssertionError`.
- `http.Client` injection via the new `client:` parameter — enables
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

### Changed
- `ViesProvider` is now an `abstract final class` with a private constructor
  — no longer instantiable.
- Internal modules split out of the provider for clarity and testability:
  - `xml_codec.dart` — XML escape/unescape and tag extraction.
  - `vat_shape.dart` — offline VAT regex validation.
  - `soap_parser.dart` — SOAP body → `ViesValidationResponse` decoding.
  The provider itself now only owns the public API, the HTTP call, and the
  retry loop.
- Pre-compiled all regular expressions (one-time cost per process).
- Cleaner SOAP body template using `{countryCode}` / `{vatNumber}` markers.
- HTTP headers no longer include `Host` / `Connection` (handled by the
  transport) and use a sensible `Content-Type`.
- Robust namespace handling — parser tolerates any prefix on SOAP and VIES
  elements and arbitrary attributes on tags.
- `requestDate` in regex-only mode is now a proper ISO 8601 UTC timestamp.
- Empty `name` / `address` values are normalised to `null`.

### Fixed
- Removed the `dart:io` import (used only for `SocketException`) which broke
  Flutter web compilation. Transport failures are now classified from
  `http.ClientException` and work on every platform, web included.
- Catch-all that previously swallowed `ViesClientError` from the parsing
  path and reported every failure as `SERVER_DISCONNECTED`.
- Typo in error code `SERVER_DICONNECTED` → `SERVER_DISCONNECTED` (now
  exposed only via `ViesErrorCode.serverDisconnected.wireName`).
- Iceland country code corrected from `IC` to `IS`.
- Regex shape errors now raise `ViesClientError` (was `ViesServerError`).

### Removed
- `html_unescape` dependency — replaced by an in-package XML entity decoder.
- `ViesProvider.classId` field (was test-only scaffolding).
- The standalone `viesErrors` map — error messages now live on
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
+   // Invalid VAT, parsing errors, INVALID_INPUT faults …
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
