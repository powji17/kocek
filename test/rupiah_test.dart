import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/core/utils/rupiah.dart';

void main() {
  group('formatRupiah', () {
    test('nol', () => expect(formatRupiah(0), 'Rp0'));
    test('di bawah seribu', () => expect(formatRupiah(750), 'Rp750'));
    test('ribuan', () => expect(formatRupiah(1000), 'Rp1.000'));
    test('jutaan', () => expect(formatRupiah(1500000), 'Rp1.500.000'));
    test('puluhan juta', () => expect(formatRupiah(25000000), 'Rp25.000.000'));
    test('negatif', () => expect(formatRupiah(-240000), '-Rp240.000'));
    test('dengan tanda plus', () {
      expect(formatRupiah(50000, withSign: true), '+Rp50.000');
    });
    test('nol dengan tanda tidak diberi plus', () {
      expect(formatRupiah(0, withSign: true), 'Rp0');
    });
  });

  group('formatThousands', () {
    test('tanpa awalan Rp', () => expect(formatThousands(1500000), '1.500.000'));
    test('kecil', () => expect(formatThousands(42), '42'));
    test('negatif dibaca positif', () => expect(formatThousands(-2500), '2.500'));
  });

  group('parseRupiahInput', () {
    test('teks berformat', () => expect(parseRupiahInput('Rp 1.500.000'), 1500000));
    test('hanya angka', () => expect(parseRupiahInput('25000'), 25000));
    test('kosong', () => expect(parseRupiahInput(''), 0));
    test('tanpa angka', () => expect(parseRupiahInput('Rp'), 0));
  });

  group('formatCompactRupiah', () {
    test('di bawah seribu apa adanya', () {
      expect(formatCompactRupiah(0), '0');
      expect(formatCompactRupiah(999), '999');
    });
    test('ribuan', () {
      expect(formatCompactRupiah(1000), '1 rb');
      expect(formatCompactRupiah(1500), '1,5 rb');
      expect(formatCompactRupiah(250000), '250 rb');
    });
    test('jutaan', () {
      expect(formatCompactRupiah(1000000), '1 jt');
      expect(formatCompactRupiah(2800000), '2,8 jt');
      expect(formatCompactRupiah(999950), '1 jt');
    });
    test('miliar', () {
      expect(formatCompactRupiah(1200000000), '1,2 M');
    });
    test('negatif', () {
      expect(formatCompactRupiah(-500000), '-500 rb');
    });
  });
}
