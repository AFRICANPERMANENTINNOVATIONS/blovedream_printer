import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrintAlign', () {
    test('values match the native API', () {
      expect(PrintAlign.left.value, 1);
      expect(PrintAlign.center.value, 2);
      expect(PrintAlign.right.value, 3);
    });
  });

  group('BarCodeType', () {
    test('values match the native API', () {
      expect(BarCodeType.upcA.value, 0x41);
      expect(BarCodeType.upcE.value, 0x42);
      expect(BarCodeType.ean13.value, 0x43);
      expect(BarCodeType.ean8.value, 0x44);
      expect(BarCodeType.code39.value, 0x45);
      expect(BarCodeType.itf.value, 0x46);
      expect(BarCodeType.codabar.value, 0x47);
      expect(BarCodeType.code93.value, 0x48);
      expect(BarCodeType.code128.value, 0x49);
    });
  });

  group('FontSize', () {
    test('values are 1..8', () {
      expect(FontSize.small.value, 1);
      expect(FontSize.middle.value, 3);
      expect(FontSize.xSuper.value, 8);
    });
  });

  group('Density', () {
    test('values are 1..10', () {
      expect(Density.small.value, 1);
      expect(Density.middle.value, 3);
      expect(Density.xxSuper.value, 10);
    });
  });

  group('HriPosition', () {
    test('values match the native API', () {
      expect(HriPosition.none.value, 1);
      expect(HriPosition.above.value, 2);
      expect(HriPosition.below.value, 3);
      expect(HriPosition.both.value, 4);
    });
  });

  group('PrinterErrorCode', () {
    test('common codes round-trip through fromValue', () {
      expect(PrinterErrorCode.fromValue(0x00), PrinterErrorCode.noError);
      expect(PrinterErrorCode.fromValue(0x03), PrinterErrorCode.printNoPaper);
      expect(PrinterErrorCode.fromValue(0xff), PrinterErrorCode.unknown);
    });

    test('unmapped values fall back to unknown', () {
      expect(PrinterErrorCode.fromValue(0x99), PrinterErrorCode.unknown);
    });
  });
}
