import 'package:flutter_test/flutter_test.dart';
import 'package:wc_cardano_example/wallet/signing_display.dart';

void main() {
  group('SigningDisplay', () {
    test('renders UTF-8 payloads for approval', () {
      expect(SigningDisplay.formatPayloadUtf8('48656c6c6f'), 'Hello');
    });

    test('falls back to the original malformed payload', () {
      expect(SigningDisplay.formatPayloadUtf8('not-hex'), 'not-hex');
    });

    test('builds preprod explorer URLs', () {
      expect(
        SigningDisplay.cardanoscanPreprodTxUrl('abc123'),
        'https://preprod.cardanoscan.io/transaction/abc123',
      );
    });
  });
}
