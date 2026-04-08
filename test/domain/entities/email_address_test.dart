import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/email_address.dart';

void main() {
  group('EmailAddress', () {
    group('constructor', () {
      test('creates with address and displayName', () {
        const addr = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice Smith',
        );

        expect(addr.address, 'alice@example.com');
        expect(addr.displayName, 'Alice Smith');
      });

      test('creates with address only (displayName null)', () {
        const addr = EmailAddress(address: 'bob@test.com');

        expect(addr.address, 'bob@test.com');
        expect(addr.displayName, isNull);
      });
    });

    group('label', () {
      test('returns "Name <addr>" when displayName is present', () {
        const addr = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice Smith',
        );

        expect(addr.label, 'Alice Smith <alice@example.com>');
      });

      test('returns address when displayName is null', () {
        const addr = EmailAddress(address: 'bob@test.com');

        expect(addr.label, 'bob@test.com');
      });

      test('returns address when displayName is empty', () {
        const addr = EmailAddress(
          address: 'bob@test.com',
          displayName: '',
        );

        expect(addr.label, 'bob@test.com');
      });
    });

    group('shortLabel', () {
      test('returns displayName when present', () {
        const addr = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice',
        );

        expect(addr.shortLabel, 'Alice');
      });

      test('returns address when displayName is null', () {
        const addr = EmailAddress(address: 'bob@test.com');

        expect(addr.shortLabel, 'bob@test.com');
      });
    });

    group('initial', () {
      test('returns first letter of displayName uppercased', () {
        const addr = EmailAddress(
          address: 'alice@example.com',
          displayName: 'alice',
        );

        expect(addr.initial, 'A');
      });

      test('returns first letter of address when no displayName', () {
        const addr = EmailAddress(address: 'bob@test.com');

        expect(addr.initial, 'B');
      });

      test('returns first letter of address when displayName is empty', () {
        const addr = EmailAddress(
          address: 'charlie@test.com',
          displayName: '',
        );

        expect(addr.initial, 'C');
      });
    });

    group('toJson / fromJson', () {
      test('round-trips with displayName', () {
        const original = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice Smith',
        );

        final json = original.toJson();
        final restored = EmailAddress.fromJson(json);

        expect(restored.address, original.address);
        expect(restored.displayName, original.displayName);
      });

      test('round-trips without displayName', () {
        const original = EmailAddress(address: 'bob@test.com');

        final json = original.toJson();
        final restored = EmailAddress.fromJson(json);

        expect(restored.address, original.address);
        expect(restored.displayName, isNull);
      });

      test('toJson produces correct keys', () {
        const addr = EmailAddress(
          address: 'a@b.com',
          displayName: 'A',
        );
        final json = addr.toJson();

        expect(json, {
          'address': 'a@b.com',
          'displayName': 'A',
        });
      });
    });

    group('equality', () {
      test('two addresses with same email are equal (case-insensitive)', () {
        const a = EmailAddress(address: 'Alice@Example.COM');
        const b = EmailAddress(address: 'alice@example.com');

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different addresses are not equal', () {
        const a = EmailAddress(address: 'alice@example.com');
        const b = EmailAddress(address: 'bob@example.com');

        expect(a, isNot(equals(b)));
      });

      test('same address with different displayNames are still equal', () {
        const a = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice',
        );
        const b = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice Smith',
        );

        expect(a, equals(b));
      });
    });

    group('toString', () {
      test('returns label representation', () {
        const addr = EmailAddress(
          address: 'alice@example.com',
          displayName: 'Alice',
        );

        expect(addr.toString(), addr.label);
      });
    });
  });
}
