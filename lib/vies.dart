/// Dart client for the VIES (VAT Information Exchange System) SOAP service.
///
/// See [ViesProvider.validateVat] for the entry point.
library;

// `soapBodyTemplate` and `viesHeaders` stay internal: they describe how the
// request is built, which is not part of the contract this package offers.
export 'src/constants.dart'
    show
        defaultRequestTimeout,
        europeanCountries,
        maxRetryBackoff,
        viesServiceUrl,
        viesTestServiceUrl;
export 'src/enums.dart';
export 'src/error_code.dart';
export 'src/models/country.dart';
export 'src/models/vies_error.dart';
export 'src/models/vies_validation_response.dart';
export 'src/vat_shape.dart';
export 'src/vies_provider.dart';
