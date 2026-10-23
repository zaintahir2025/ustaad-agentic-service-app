import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/core/validation.dart';

void main() {
  group('PakistaniPhoneValidator Tests', () {
    test('validates standard local 11-digit mobile numbers', () {
      expect(PakistaniPhoneValidator.isValid('03001234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('03129876543'), isTrue);
      expect(PakistaniPhoneValidator.isValid('03335555555'), isTrue);
      expect(PakistaniPhoneValidator.isValid('03451122334'), isTrue);
      expect(PakistaniPhoneValidator.isValid('03551234567'), isTrue); // SCOM
    });

    test('validates formatted numbers with hyphens and spaces', () {
      expect(PakistaniPhoneValidator.isValid('0300-1234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('0300 1234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('+92 300 1234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('+92-300-1234567'), isTrue);
    });

    test('validates international dialing formats (+92, 0092, 92)', () {
      expect(PakistaniPhoneValidator.isValid('+923001234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('00923001234567'), isTrue);
      expect(PakistaniPhoneValidator.isValid('923001234567'), isTrue);
    });

    test('rejects invalid or foreign numbers', () {
      expect(PakistaniPhoneValidator.isValid(''), isFalse);
      expect(PakistaniPhoneValidator.isValid(null), isFalse);
      expect(PakistaniPhoneValidator.isValid('02134567890'), isFalse); // Landline
      expect(PakistaniPhoneValidator.isValid('+14155552671'), isFalse); // US
      expect(PakistaniPhoneValidator.isValid('0300123'), isFalse); // Too short
      expect(PakistaniPhoneValidator.isValid('0300123456789'), isFalse); // Too long
      expect(PakistaniPhoneValidator.isValid('03601234567'), isFalse); // Invalid operator code
      expect(PakistaniPhoneValidator.isValid('abcdefghijk'), isFalse);
    });

    test('normalizes numbers to standard +923XXXXXXXXX E.164 format', () {
      expect(PakistaniPhoneValidator.normalize('03001234567'), equals('+923001234567'));
      expect(PakistaniPhoneValidator.normalize('0300-1234567'), equals('+923001234567'));
      expect(PakistaniPhoneValidator.normalize('00923001234567'), equals('+923001234567'));
      expect(PakistaniPhoneValidator.normalize('923001234567'), equals('+923001234567'));
      expect(PakistaniPhoneValidator.normalize('+923001234567'), equals('+923001234567'));
    });

    test('detects correct Pakistani telecom operators', () {
      expect(PakistaniPhoneValidator.detectOperator('03001234567'), equals('Jazz'));
      expect(PakistaniPhoneValidator.detectOperator('03211234567'), equals('Jazz'));
      expect(PakistaniPhoneValidator.detectOperator('03121234567'), equals('Zong'));
      expect(PakistaniPhoneValidator.detectOperator('03331234567'), equals('Ufone'));
      expect(PakistaniPhoneValidator.detectOperator('03451234567'), equals('Telenor'));
      expect(PakistaniPhoneValidator.detectOperator('03551234567'), equals('SCOM'));
      expect(PakistaniPhoneValidator.detectOperator('09991234567'), equals('Unknown'));
    });

    test('validate helper returns null for valid and error string for invalid', () {
      expect(PakistaniPhoneValidator.validate('03001234567'), isNull);
      expect(PakistaniPhoneValidator.validate(''), isNotNull);
      expect(PakistaniPhoneValidator.validate('invalid'), contains('valid Pakistani mobile'));
    });
  });

  group('PakistaniAddressValidator Tests', () {
    test('validates standard Pakistani residential and commercial addresses', () {
      final res1 = PakistaniAddressValidator.validate('House 14, Street 25, G-13/2, Islamabad');
      expect(res1.isValid, isTrue);
      expect(res1.city, equals('Islamabad'));
      expect(res1.sector, equals('G-13/2'));

      final res2 = PakistaniAddressValidator.validate('Plaza 3B, Sector F-10 Markaz, Islamabad');
      expect(res2.isValid, isTrue);
      expect(res2.city, equals('Islamabad'));
      expect(res2.sector, equals('F-10'));

      final res3 = PakistaniAddressValidator.validate('DHA Phase 2, Sector B, Rawalpindi');
      expect(res3.isValid, isTrue);
      expect(res3.city, equals('Rawalpindi'));
      expect(res3.sector, equals('DHA Phase 2'));

      final res4 = PakistaniAddressValidator.validate('Main Boulevard, Gulberg III, Lahore');
      expect(res4.isValid, isTrue);
      expect(res4.city, equals('Lahore'));
      expect(res4.sector, equals('Gulberg III'));
    });

    test('sanitizes input and strips dangerous script tags and control characters', () {
      final dirty = '<script>alert("hack")</script> House 12, G-13, Islamabad';
      final res = PakistaniAddressValidator.validate(dirty);
      // Contains script keyword, correctly flagged
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('prohibited'));

      final cleaned = PakistaniAddressValidator.sanitize('<b>House 12</b>, G-13, Islamabad');
      expect(cleaned, equals('House 12, G-13, Islamabad'));
    });

    test('validates minimum and maximum address lengths', () {
      final tooShort = PakistaniAddressValidator.validate('Abc');
      expect(tooShort.isValid, isFalse);
      expect(tooShort.errorMessage, contains('too short'));

      final empty = PakistaniAddressValidator.validate('   ');
      expect(empty.isValid, isFalse);
      expect(empty.errorMessage, equals('Address is required.'));

      final tooLong = PakistaniAddressValidator.validate('A' * 350);
      expect(tooLong.isValid, isFalse);
      expect(tooLong.errorMessage, contains('exceeds maximum length'));
    });

    test('formFieldValidator returns null for valid and error string for invalid', () {
      expect(PakistaniPhoneValidator.validate('+923001234567'), isNull);
      expect(PakistaniAddressValidator.formFieldValidator('House 5, Street 2, F-7, Islamabad'), isNull);
      expect(PakistaniAddressValidator.formFieldValidator(''), equals('Address is required.'));
    });
  });
}
