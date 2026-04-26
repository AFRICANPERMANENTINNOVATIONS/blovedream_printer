import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrintCallbackEvent', () {
    test('isSuccess is true only for noError', () {
      expect(const PrintCallbackEvent(PrinterErrorCode.noError).isSuccess, true);
      expect(
        const PrintCallbackEvent(PrinterErrorCode.printNoPaper).isSuccess,
        false,
      );
    });

    test('toString includes the error name', () {
      expect(
        const PrintCallbackEvent(PrinterErrorCode.printNoPaper).toString(),
        contains('printNoPaper'),
      );
    });
  });

  group('PrinterVersionEvent', () {
    test('toString includes the version string', () {
      expect(
        const PrinterVersionEvent('1.2.3').toString(),
        contains('1.2.3'),
      );
    });
  });
}
