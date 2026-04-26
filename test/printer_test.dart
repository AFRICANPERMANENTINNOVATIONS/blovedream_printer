import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('africa.permanentinnovations/blovedream_printer');
  final List<MethodCall> calls = <MethodCall>[];
  late Object? Function(MethodCall) handler;

  setUp(() {
    calls.clear();
    handler = (MethodCall call) {
      // Default: success
      return null;
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('BlovedreamPrinter', () {
    test('open() invokes the open method', () async {
      await BlovedreamPrinter.instance.open();
      expect(calls.single.method, 'open');
    });

    test('close() invokes the close method', () async {
      await BlovedreamPrinter.instance.close();
      expect(calls.single.method, 'close');
    });

    test('start() invokes the start method', () async {
      await BlovedreamPrinter.instance.start();
      expect(calls.single.method, 'start');
    });

    test('printText forwards text and config', () async {
      await BlovedreamPrinter.instance.printText(
        'hello',
        align: PrintAlign.center,
        fontSize: FontSize.large,
        bold: true,
        underline: false,
      );
      expect(calls.single.method, 'printText');
      expect(calls.single.arguments, <String, Object?>{
        'text': 'hello',
        'align': PrintAlign.center.value,
        'fontSize': FontSize.large.value,
        'bold': true,
        'underline': false,
      });
    });

    test('printBarcode uses CODE128 by default', () async {
      await BlovedreamPrinter.instance.printBarcode('123456789012');
      expect(calls.single.arguments, <String, Object?>{
        'type': BarCodeType.code128.value,
        'content': '123456789012',
        'hri': HriPosition.below.value,
        'height': 3,
        'unitWidth': 3,
      });
    });

    test('printQr uses center alignment and size 384 by default', () async {
      await BlovedreamPrinter.instance.printQr('https://example.com');
      expect(calls.single.arguments, <String, Object?>{
        'content': 'https://example.com',
        'align': PrintAlign.center.value,
        'size': 384,
      });
    });

    test('lineFeed forwards the count', () async {
      await BlovedreamPrinter.instance.lineFeed(5);
      expect(calls.single.arguments, {'lines': 5});
    });

    test('setDensity forwards the int value', () async {
      await BlovedreamPrinter.instance.setDensity(Density.xLarge);
      expect(calls.single.method, 'setDensity');
      expect(calls.single.arguments, {'density': Density.xLarge.value});
    });

    test('goToNextMark uses 1000 by default', () async {
      await BlovedreamPrinter.instance.goToNextMark();
      expect(calls.single.arguments, {'feedSpace': 1000});
    });

    test('getSupportPrint returns 0 when native returns null', () async {
      handler = (call) => null;
      final v = await BlovedreamPrinter.instance.getSupportPrint();
      expect(v, 0);
    });

    test('getSupportPrint returns native value when present', () async {
      handler = (call) => 1;
      final v = await BlovedreamPrinter.instance.getSupportPrint();
      expect(v, 1);
    });
  });
}
