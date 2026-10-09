import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';

void main() {
  group('LocalizedText', () {
    test('valid construction', () {
      final text = LocalizedText(
        english: 'Hello',
        kannada: 'ಹಲೋ',
        malayalam: 'ഹലോ',
      );

      expect(text.english, 'Hello');
      expect(text.kannada, 'ಹಲೋ');
      expect(text.malayalam, 'ഹലോ');
      expect(text.toString(), 'Hello');
    });

    test('equality', () {
      final t1 = LocalizedText(english: 'A', kannada: 'B');
      final t2 = LocalizedText(english: 'A', kannada: 'B');
      final t3 = LocalizedText(english: 'A', kannada: 'C');

      expect(t1, t2);
      expect(t1.hashCode, t2.hashCode);
      expect(t1, isNot(t3));
    });

    test('invalid required values throw ArgumentError', () {
      expect(() => LocalizedText(english: ''), throwsArgumentError);
      expect(() => LocalizedText(english: '   '), throwsArgumentError);
    });
  });
}
