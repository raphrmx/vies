/// Minimal XML codec used to talk to the VIES SOAP service.
///
/// VIES responses use a small, predictable subset of XML - no CDATA, no
/// processing instructions, only the five predefined entities plus numeric
/// character references. A full-blown XML parser would be overkill (and a
/// transitive dependency); this codec covers exactly what's needed.
library;

/// Static helpers - not meant to be instantiated.
abstract final class XmlCodec {
  XmlCodec._();

  /// Numeric XML entity (decimal): `&#39;` -> `'`.
  static final RegExp _decEntity = RegExp(r'&#(\d+);');

  /// Numeric XML entity (hexadecimal): `&#x27;` -> `'`.
  static final RegExp _hexEntity = RegExp('&#x([0-9a-fA-F]+);');

  /// Matches `<soap:Fault>...</soap:Fault>` regardless of namespace prefix.
  static final RegExp faultRegex = RegExp(
    r'<(?:\w+:)?Fault\b[^>]*>([\s\S]*?)</(?:\w+:)?Fault>',
  );

  /// Cache of compiled tag-matching regexes, keyed by local element name.
  static final Map<String, RegExp> _fieldRegexCache = {};

  /// Escape a string so it is safe to embed in an XML element value or
  /// attribute. Escapes the five predefined XML entities.
  static String escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Reverse of [escape]. Also decodes numeric character references
  /// (`&#39;`, `&#x27;`) that VIES may emit for non-ASCII business names.
  ///
  /// A reference that names no valid code point is left in place rather than
  /// raising: the body comes off the network, and a malformed one must surface
  /// as a [ViesError] from the parser, never as a raw [RangeError].
  static String unescape(String value) => value
      .replaceAllMapped(_decEntity, (m) => _decodeReference(m, 10))
      .replaceAllMapped(_hexEntity, (m) => _decodeReference(m, 16))
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      // Must be last to avoid double-decoding sequences like `&amp;lt;`.
      .replaceAll('&amp;', '&');

  /// Decodes one numeric character reference, or returns it untouched when it
  /// is out of the Unicode range or too large to parse.
  static String _decodeReference(Match match, int radix) {
    final code = int.tryParse(match.group(1)!, radix: radix);
    if (code == null || code < 0 || code > 0x10FFFF) return match.group(0)!;
    return String.fromCharCode(code);
  }

  /// Extract the text content of the first element whose local name matches
  /// [localName]. Ignores any XML namespace prefix and tolerates arbitrary
  /// attributes on the opening tag. Returns `null` when no match is found.
  ///
  /// The text content is automatically XML-unescaped.
  static String? parseField(String xml, String localName) {
    final regex = _fieldRegexCache.putIfAbsent(
      localName,
      () => RegExp(
        '<(?:\\w+:)?$localName(?:\\s[^>]*)?>([\\s\\S]*?)</(?:\\w+:)?$localName>',
      ),
    );
    final match = regex.firstMatch(xml);
    final raw = match?.group(1);
    return raw == null ? null : unescape(raw);
  }
}
