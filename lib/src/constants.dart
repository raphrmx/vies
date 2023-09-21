///
/// Vies Vat checker API path's
///
const viesServiceUrl = "https://ec.europa.eu/taxation_customs/vies/services/checkVatService";
const viesTestServiceUrl = "https://ec.europa.eu/taxation_customs/vies/services/checkVatTestService";
const defaultRequestTimeout = Duration(seconds: 30);

const euCountries = [
  {"name": "Andorra", "code": "AD"},
  {"name": "Albania", "code": "AL"},
  {"name": "Austria", "code": "AT"},
  {"name": "Åland Islands", "code": "AX"},
  {"name": "Bosnia and Herzegovina", "code": "BA"},
  {"name": "Belgium", "code": "BE"},
  {"name": "Bulgaria", "code": "BG"},
  {"name": "Belarus", "code": "BY"},
  {"name": "Switzerland", "code": "CH"},
  {"name": "Cyprus", "code": "CY"},
  {"name": "Czech Republic", "code": "CZ"},
  {"name": "Germany", "code": "DE"},
  {"name": "Denmark", "code": "DK"},
  {"name": "Estonia", "code": "EE"},
  {"name": "Spain", "code": "ES"},
  {"name": "Finland", "code": "FI"},
  {"name": "Faroe Islands", "code": "FO"},
  {"name": "France", "code": "FR"},
  {"name": "United Kingdom", "code": "GB"},
  {"name": "Guernsey", "code": "GG"},
  {"name": "Greece", "code": "GR"},
  {"name": "Croatia", "code": "HR"},
  {"name": "Hungary", "code": "HU"},
  {"name": "Ireland", "code": "IE"},
  {"name": "Isle of Man", "code": "IM"},
  {"name": "Iceland", "code": "IC"},
  {"name": "Italy", "code": "IT"},
  {"name": "Jersey", "code": "JE"},
  {"name": "Liechtenstein", "code": "LI"},
  {"name": "Lithuania", "code": "LT"},
  {"name": "Luxembourg", "code": "LU"},
  {"name": "Latvia", "code": "LV"},
  {"name": "Monaco", "code": "MC"},
  {"name": "Moldova, Republic of", "code": "MD"},
  {"name": "Macedonia, The Former Yugoslav Republic of", "code": "MK"},
  {"name": "Malta", "code": "MT"},
  {"name": "Netherlands", "code": "NL"},
  {"name": "Norway", "code": "NO"},
  {"name": "Poland", "code": "PL"},
  {"name": "Portugal", "code": "PT"},
  {"name": "Romania", "code": "RO"},
  {"name": "Russian Federation", "code": "RU"},
  {"name": "Sweden", "code": "SE"},
  {"name": "Slovenia", "code": "SI"},
  {"name": "Svalbard and Jan Mayen", "code": "SJ"},
  {"name": "Slovakia", "code": "SK"},
  {"name": "San Marino", "code": "SM"},
  {"name": "Ukraine", "code": "UA"},
  {"name": "Holy See (Vatican City State)", "code": "VA"},
];

const viesErrors = {
  "INVALID_INPUT": "The provided CountryCode is invalid or the VAT number is empty",
  "SERVICE_UNAVAILABLE": "The VIES VAT service is unavailable, please try again later",
  "MS_UNAVAILABLE": "The VAT database of the requested member country is unavailable, please try again later",
  "MS_MAX_CONCURRENT_REQ": "The VAT database of the requested member country has had too many requests, please try again later",
  "TIMEOUT": "The request to VAT database of the requested member country has timed out, please try again later",
  "SOCKET_EXCEPTION": "The service cannot process your request, internet disconnected. Please check your internet connection and try again later",
  "SERVER_BUSY": "The service cannot process your request, please try again later",
  "SERVER_DICONNECTED": "The service cannot process your request, service disconnected. Please try again later",
  "INVALID_REQUESTER_INFO": "The requester info is invalid",
  "PARSING_ERROR": "Failed to parse vat validation info from VIES response",
  "INVALID_VAT_NUMBER": "Your VAT number is invalid. Please check it and try again",
  "UNKNOWN": "Unknown error",
};

///
/// Http request body template
/// Replace _country_code_placeholder_ and _vat_number_placeholder_ before send request of VAT validation
///
const soapBodyTemplate = '''
  <?xml version="1.0"?>
  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
    <soapenv:Header/>
    <soapenv:Body>
      <urn:checkVat>
         <urn:countryCode>_country_code_placeholder_</urn:countryCode>
         <urn:vatNumber>_vat_number_placeholder_</urn:vatNumber>
      </urn:checkVat>
    </soapenv:Body>
  </soapenv:Envelope>
  ''';

///
/// Http request headers to use SOAP Vies API
///
const viesHeaders = {
  "Content-Type": "text/xml",
  "User-Agent": "dart-soap",
  "Accept": "text/html,application/xhtml+xml,application/xml,text/xml;q=0.9,*/*;q=0.8",
  "Accept-Encoding": "gzip,deflate",
  "SOAPAction": "",
  "Accept-Charset": "utf-8",
  "Connection": "Keep-Alive",
  "Host": "ec.europa.eu",
};
