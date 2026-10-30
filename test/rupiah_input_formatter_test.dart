import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/core/utils/rupiah_input_formatter.dart';

TextEditingValue format(String input) {
  return const RupiahInputFormatter().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: input),
  );
}

void main() {
  test('memberi pemisah ribuan saat mengetik', () {
    expect(format('1500000').text, '1.500.000');
    expect(format('1.5000').text, '15.000');
  });

  test('membuang karakter selain angka', () {
    expect(format('Rp abc 250').text, '250');
    expect(format('abc').text, '');
  });

  test('membuang nol di depan', () {
    expect(format('0012').text, '12');
  });

  test('dibatasi 12 digit', () {
    expect(format('1234567890123').text, '123.456.789.012');
  });

  test('kursor selalu di akhir teks', () {
    final v = format('1500000');
    expect(v.selection.baseOffset, v.text.length);
  });
}
