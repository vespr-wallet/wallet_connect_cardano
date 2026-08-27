import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

void main() {
  group('CardanoExtension', () {
    test('round-trips JSON', () {
      const extension = CardanoExtension(cip: 95);

      expect(extension.toJson(), <String, Object>{'cip': 95});
      expect(CardanoExtension.fromJson(extension.toJson()).cip, 95);
    });
  });

  group('CardanoPaginate', () {
    test('round-trips JSON', () {
      const paginate = CardanoPaginate(page: 2, limit: 25);

      expect(paginate.toJson(), <String, Object>{'page': 2, 'limit': 25});
      final decoded = CardanoPaginate.fromJson(paginate.toJson());
      expect(decoded.page, 2);
      expect(decoded.limit, 25);
      expect(decoded.toString(), 'CardanoPaginate(page: 2, limit: 25)');
    });
  });

  group('CardanoDataSignature', () {
    test('round-trips JSON', () {
      const signature = CardanoDataSignature(
        signature: 'd8799f',
        key: 'a40101',
      );

      expect(signature.toJson(), <String, Object>{
        'signature': 'd8799f',
        'key': 'a40101',
      });
      final decoded = CardanoDataSignature.fromJson(signature.toJson());
      expect(decoded.signature, 'd8799f');
      expect(decoded.key, 'a40101');
    });
  });

  group('CardanoApiError', () {
    test('defines CIP-30 error codes', () {
      expect(CardanoApiError.invalidRequest, -1);
      expect(CardanoApiError.internalError, -2);
      expect(CardanoApiError.refused, -3);
      expect(CardanoApiError.accountChange, -4);
    });

    test('round-trips JSON and renders diagnostics', () {
      const error = CardanoApiError(
        code: CardanoApiError.refused,
        info: 'Request refused',
      );

      expect(error.toJson(), <String, Object>{
        'code': -3,
        'info': 'Request refused',
      });
      final decoded = CardanoApiError.fromJson(error.toJson());
      expect(decoded.code, CardanoApiError.refused);
      expect(decoded.info, 'Request refused');
      expect(
        decoded.toString(),
        'CardanoApiError(code: -3, info: Request refused)',
      );
    });
  });

  group('CardanoDataSignError', () {
    test('defines CIP-30 error codes', () {
      expect(CardanoDataSignError.proofGeneration, 1);
      expect(CardanoDataSignError.addressNotPK, 2);
      expect(CardanoDataSignError.userDeclined, 3);
    });

    test('round-trips JSON', () {
      const error = CardanoDataSignError(
        code: CardanoDataSignError.addressNotPK,
        info: 'Not a public-key address',
      );

      final decoded = CardanoDataSignError.fromJson(error.toJson());
      expect(decoded.code, CardanoDataSignError.addressNotPK);
      expect(decoded.info, 'Not a public-key address');
    });
  });

  group('CardanoTxSignError', () {
    test('defines CIP-30 error codes', () {
      expect(CardanoTxSignError.proofGeneration, 1);
      expect(CardanoTxSignError.userDeclined, 2);
    });

    test('round-trips JSON', () {
      const error = CardanoTxSignError(
        code: CardanoTxSignError.userDeclined,
        info: 'Declined',
      );

      final decoded = CardanoTxSignError.fromJson(error.toJson());
      expect(decoded.code, CardanoTxSignError.userDeclined);
      expect(decoded.info, 'Declined');
    });
  });

  group('CardanoTxSendError', () {
    test('defines CIP-30 error codes', () {
      expect(CardanoTxSendError.refused, 1);
      expect(CardanoTxSendError.failure, 2);
    });

    test('round-trips JSON', () {
      const error = CardanoTxSendError(
        code: CardanoTxSendError.failure,
        info: 'Submission failed',
      );

      final decoded = CardanoTxSendError.fromJson(error.toJson());
      expect(decoded.code, CardanoTxSendError.failure);
      expect(decoded.info, 'Submission failed');
    });
  });

  group('CardanoPaginateError', () {
    test('round-trips JSON', () {
      const error = CardanoPaginateError(maxSize: 100);

      expect(error.toJson(), <String, Object>{'maxSize': 100});
      expect(CardanoPaginateError.fromJson(error.toJson()).maxSize, 100);
    });
  });
}
