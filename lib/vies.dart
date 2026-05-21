/// Dart client for the VIES (VAT Information Exchange System) SOAP service.
///
/// See [ViesProvider.validateVat] for the entry point.
library;

export 'src/constants.dart'
    show
        defaultRequestTimeout,
        europeanCountries,
        soapBodyTemplate,
        viesHeaders,
        viesServiceUrl,
        viesTestServiceUrl;
export 'src/enums.dart';
export 'src/error_code.dart';
export 'src/models/country.dart';
export 'src/models/vies_error.dart';
export 'src/models/vies_validation_response.dart';
export 'src/vies_provider.dart';
