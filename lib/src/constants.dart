// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:vies/src/models/country.dart';

/// Production endpoint of the VIES `checkVat` SOAP service.
const String viesServiceUrl =
    'https://ec.europa.eu/taxation_customs/vies/services/checkVatService';

/// Test endpoint of the VIES `checkVat` service — returns deterministic
/// success/failure based on the VAT number tail, useful for integration
/// testing without hitting the real database.
const String viesTestServiceUrl =
    'https://ec.europa.eu/taxation_customs/vies/services/checkVatTestService';

/// Default timeout applied to a VIES call when the caller does not override
/// it.
const Duration defaultRequestTimeout = Duration(seconds: 30);

/// Convenience list of European country codes the package may encounter when
/// dealing with VAT numbers. This is **not** a strict list of EU member
/// states — it includes EEA neighbours and a few other European territories
/// that frequently appear in business directories.
///
/// Note: the canonical codes used by VIES are mostly ISO 3166-1 alpha-2, with
/// two important exceptions:
///   * `EL` for Greece (instead of `GR`).
///   * `XI` for Northern Ireland (post-Brexit; not in this list because it
///     is not a country in itself).
const List<Country> europeanCountries = [
  Country(name: 'Andorra', code: 'AD'),
  Country(name: 'Albania', code: 'AL'),
  Country(name: 'Austria', code: 'AT'),
  Country(name: 'Åland Islands', code: 'AX'),
  Country(name: 'Bosnia and Herzegovina', code: 'BA'),
  Country(name: 'Belgium', code: 'BE'),
  Country(name: 'Bulgaria', code: 'BG'),
  Country(name: 'Belarus', code: 'BY'),
  Country(name: 'Switzerland', code: 'CH'),
  Country(name: 'Cyprus', code: 'CY'),
  Country(name: 'Czech Republic', code: 'CZ'),
  Country(name: 'Germany', code: 'DE'),
  Country(name: 'Denmark', code: 'DK'),
  Country(name: 'Estonia', code: 'EE'),
  Country(name: 'Greece', code: 'EL'),
  Country(name: 'Spain', code: 'ES'),
  Country(name: 'Finland', code: 'FI'),
  Country(name: 'Faroe Islands', code: 'FO'),
  Country(name: 'France', code: 'FR'),
  Country(name: 'United Kingdom', code: 'GB'),
  Country(name: 'Guernsey', code: 'GG'),
  Country(name: 'Croatia', code: 'HR'),
  Country(name: 'Hungary', code: 'HU'),
  Country(name: 'Ireland', code: 'IE'),
  Country(name: 'Isle of Man', code: 'IM'),
  Country(name: 'Iceland', code: 'IS'),
  Country(name: 'Italy', code: 'IT'),
  Country(name: 'Jersey', code: 'JE'),
  Country(name: 'Liechtenstein', code: 'LI'),
  Country(name: 'Lithuania', code: 'LT'),
  Country(name: 'Luxembourg', code: 'LU'),
  Country(name: 'Latvia', code: 'LV'),
  Country(name: 'Monaco', code: 'MC'),
  Country(name: 'Moldova, Republic of', code: 'MD'),
  Country(name: 'Macedonia, The Former Yugoslav Republic of', code: 'MK'),
  Country(name: 'Malta', code: 'MT'),
  Country(name: 'Netherlands', code: 'NL'),
  Country(name: 'Norway', code: 'NO'),
  Country(name: 'Poland', code: 'PL'),
  Country(name: 'Portugal', code: 'PT'),
  Country(name: 'Romania', code: 'RO'),
  Country(name: 'Russian Federation', code: 'RU'),
  Country(name: 'Sweden', code: 'SE'),
  Country(name: 'Slovenia', code: 'SI'),
  Country(name: 'Svalbard and Jan Mayen', code: 'SJ'),
  Country(name: 'Slovakia', code: 'SK'),
  Country(name: 'San Marino', code: 'SM'),
  Country(name: 'Ukraine', code: 'UA'),
  Country(name: 'Holy See (Vatican City State)', code: 'VA'),
];

/// SOAP envelope body sent to the VIES `checkVat` operation.
///
/// `{countryCode}` and `{vatNumber}` are replaced at request time. Both
/// values are XML-escaped before substitution.
const String soapBodyTemplate =
    '<?xml version="1.0"?>'
    '<soapenv:Envelope '
    'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
    'xmlns:urn="urn:ec.europa.eu:taxud:vies:services:checkVat:types">'
    '<soapenv:Header/>'
    '<soapenv:Body>'
    '<urn:checkVat>'
    '<urn:countryCode>{countryCode}</urn:countryCode>'
    '<urn:vatNumber>{vatNumber}</urn:vatNumber>'
    '</urn:checkVat>'
    '</soapenv:Body>'
    '</soapenv:Envelope>';

/// HTTP headers required by the VIES SOAP endpoint.
///
/// `Host` and `Connection` are intentionally omitted — `package:http` and
/// the underlying `dart:io` HttpClient manage them automatically and adding
/// them by hand can break HTTP/2 connections.
const Map<String, String> viesHeaders = {
  'Content-Type': 'text/xml; charset=utf-8',
  'Accept': 'text/xml, application/xml, application/soap+xml',
  'Accept-Charset': 'utf-8',
  'SOAPAction': '',
};
