import 'package:flutter_test/flutter_test.dart';
import 'package:maps/core/validators.dart';

void main() {
  group('Validators.telCol', () {
    test('accepta celulares colombianos', () {
      expect(Validators.telCol('3001234567'), isTrue);
      expect(Validators.telCol(' 3159876543 '), isTrue);
    });

    test('acepta telefonos fijos', () {
      expect(Validators.telCol('1234567'), isTrue);
      expect(Validators.telCol('6021234567'), isTrue);
      expect(Validators.telCol('60 21234567'), isTrue);
    });

    test('rechaza formatos invalidos', () {
      expect(Validators.telCol('1234'), isFalse);
      expect(Validators.telCol('30A1234567'), isFalse);
      expect(Validators.telCol('300-1234567'), isFalse);
    });
  });

  group('Validators.horarioSimple', () {
    test('acepta horarios validos', () {
      expect(Validators.horarioSimple('L-D 08:00-18:00'), isTrue);
      expect(Validators.horarioSimple('L-S 7:00-19:00'), isTrue);
      expect(Validators.horarioSimple('Ma J 09:30-20:00'), isTrue);
    });

    test('rechaza horarios invalidos', () {
      expect(Validators.horarioSimple(''), isFalse);
      expect(Validators.horarioSimple('08:00-18:00'), isFalse);
      expect(Validators.horarioSimple('L-D 8-18'), isFalse);
    });
  });
}
