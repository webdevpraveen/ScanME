import 'package:flutter_test/flutter_test.dart';
import 'package:seeme/core/validators/input_validators.dart';

void main() {
  group('InputValidators - Email', () {
    test('valid email returns null', () {
      expect(InputValidators.email('test@mit.edu'), null);
      expect(InputValidators.email('john.doe@gmail.com'), null);
    });

    test('invalid email returns error message', () {
      expect(InputValidators.email(''), 'Email is required');
      expect(InputValidators.email(null), 'Email is required');
      expect(InputValidators.email('invalid-email'), 'Enter a valid email address');
      expect(InputValidators.email('test@'), 'Enter a valid email address');
    });
  });

  group('InputValidators - Roll Number', () {
    test('valid roll number returns null', () {
      expect(InputValidators.rollNumber('202510101310124'), null);
      expect(InputValidators.rollNumber('123456789012345'), null);
    });

    test('invalid roll number returns error message', () {
      expect(InputValidators.rollNumber(''), 'Roll number is required');
      expect(InputValidators.rollNumber(null), 'Roll number is required');
      expect(InputValidators.rollNumber('12345678901234'), 'Roll number must be exactly 15 digits');
      expect(InputValidators.rollNumber('1234567890123456'), 'Roll number must be exactly 15 digits');
      expect(InputValidators.rollNumber('20251010131012a'), 'Roll number must contain only numbers');
    });
  });

  group('InputValidators - Password', () {
    test('valid password returns null', () {
      expect(InputValidators.password('Password123'), null);
    });

    test('invalid password returns error message', () {
      expect(InputValidators.password(''), 'Password is required');
      expect(InputValidators.password('Pass'), 'Password must be at least 8 characters');
      expect(InputValidators.password('lowercase123'), 'Password must contain an uppercase letter');
      expect(InputValidators.password('UPPERCASE123'), 'Password must contain a lowercase letter');
      expect(InputValidators.password('NoNumberPass'), 'Password must contain a number');
    });
  });

  group('InputValidators - Full Name', () {
    test('valid full name returns null', () {
      expect(InputValidators.fullName('John Doe'), null);
      expect(InputValidators.fullName('Jean-Luc Picard'), null);
    });

    test('invalid name returns error message', () {
      expect(InputValidators.fullName(''), 'Full name is required');
      expect(InputValidators.fullName('A'), 'Name must be at least 2 characters');
      expect(InputValidators.fullName('John123'), 'Name can only contain letters, spaces, hyphens, and apostrophes');
    });
  });
}
