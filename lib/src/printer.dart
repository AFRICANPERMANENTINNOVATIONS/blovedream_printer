import 'dart:async';

import 'package:flutter/services.dart';

import 'enums.dart';
import 'printer_event.dart';

/// Singleton wrapper around the native Blovedream printer service.
///
/// All methods forward to the OEM `android.bld.PrintManager` via reflection
/// on the Android side. They throw a [PlatformException] if the service is
/// not available — typically because the host device is not a Blovedream
/// terminal.
///
/// Typical usage:
///
/// ```dart
/// final printer = BlovedreamPrinter.instance;
/// printer.events.listen(print);
///
/// await printer.open();
/// await printer.printText('Hello!', align: PrintAlign.center);
/// await printer.start();
/// ```
class BlovedreamPrinter {
  BlovedreamPrinter._();

  /// The single, shared printer instance.
  static final BlovedreamPrinter instance = BlovedreamPrinter._();

  static const MethodChannel _method =
      MethodChannel('africa.permanentinnovations/blovedream_printer');
  static const EventChannel _events =
      EventChannel('africa.permanentinnovations/blovedream_printer/events');

  Stream<PrintEvent>? _eventStream;

  /// Stream of printer events. Subscribing attaches the native listener; the
  /// listener is removed when there are no more subscribers.
  ///
  /// Emits [PrintCallbackEvent] on each completed job and one
  /// [PrinterVersionEvent] right after the listener is attached.
  Stream<PrintEvent> get events {
    return _eventStream ??= _events.receiveBroadcastStream().map((dynamic raw) {
      final map = (raw as Map).cast<String, Object?>();
      final type = map['type'] as String?;
      switch (type) {
        case 'onPrintCallback':
          final code = (map['errorCode'] as num?)?.toInt() ?? 0xff;
          return PrintCallbackEvent(PrinterErrorCode.fromValue(code));
        case 'onVersion':
          return PrinterVersionEvent((map['version'] as String?) ?? '');
        default:
          return PrintCallbackEvent(PrinterErrorCode.unknown);
      }
    });
  }

  // ---- lifecycle -----------------------------------------------------------

  /// Acquires the native print service. Must be called once before any
  /// other operation, typically right after the app starts.
  Future<void> open() => _method.invokeMethod<void>('open');

  /// Releases the native print service.
  Future<void> close() => _method.invokeMethod<void>('close');

  /// Commits the queued commands and triggers the actual print.
  Future<void> start() => _method.invokeMethod<void>('start');

  /// Resets the print engine, clearing any pending state.
  Future<void> reset() => _method.invokeMethod<void>('reset');

  /// Returns the firmware version string reported by the printer, or `null`
  /// if the device does not expose one.
  Future<String?> getVersion() => _method.invokeMethod<String>('getVersion');

  /// Reads the system property `ro.blovedream_support_print`.
  ///
  /// A non-zero value indicates a Blovedream device that supports the printer
  /// service. Returns `0` on devices that do not expose the property.
  Future<int> getSupportPrint() async {
    final v = await _method.invokeMethod<int>('getSupportPrint');
    return v ?? 0;
  }

  // ---- configuration -------------------------------------------------------

  /// Sets the default font size used by subsequent [printText] calls that
  /// don't override it.
  Future<void> setFontSize(FontSize size) =>
      _method.invokeMethod<void>('setFontSize', {'size': size.value});

  /// Returns the current font size as the raw native value (1–8).
  Future<int> getFontSize() async =>
      (await _method.invokeMethod<int>('getFontSize')) ?? 0;

  /// Toggles bold rendering for subsequent text.
  Future<void> setBold(bool bold) =>
      _method.invokeMethod<void>('setBold', {'bold': bold});

  /// Whether bold rendering is currently enabled.
  Future<bool> isBold() async =>
      (await _method.invokeMethod<bool>('isBold')) ?? false;

  /// Toggles underline rendering for subsequent text.
  Future<void> setUnderline(bool underline) =>
      _method.invokeMethod<void>('setUnderline', {'underline': underline});

  /// Whether underline rendering is currently enabled.
  Future<bool> isUnderline() async =>
      (await _method.invokeMethod<bool>('isUnderline')) ?? false;

  /// Toggles reverse (white-on-black) rendering.
  Future<void> setReverse(bool reverse) =>
      _method.invokeMethod<void>('setReverse', {'reverse': reverse});

  /// Whether reverse rendering is currently enabled.
  Future<bool> isReverse() async =>
      (await _method.invokeMethod<bool>('isReverse')) ?? false;

  /// Sets the print density / darkness (1–10).
  Future<void> setDensity(Density density) =>
      _method.invokeMethod<void>('setDensity', {'density': density.value});

  /// Returns the current density as the raw native value.
  Future<int> getDensity() async =>
      (await _method.invokeMethod<int>('getDensity')) ?? 0;

  /// Sets the line spacing (in arbitrary units, see firmware docs).
  Future<void> setLineSpacing(double spacing) =>
      _method.invokeMethod<void>('setLineSpacing', {'spacing': spacing});

  /// Returns the current line spacing.
  Future<double> getLineSpacing() async =>
      (await _method.invokeMethod<double>('getLineSpacing')) ?? 0.0;

  /// Enables black-mark detection for label paper.
  ///
  /// When `true`, the printer can stop the paper exactly between two labels
  /// using [goToNextMark].
  Future<void> setBlackLabel(bool enabled) =>
      _method.invokeMethod<void>('setBlackLabel', {'enabled': enabled});

  /// Whether black-mark / label mode is currently enabled.
  Future<bool> isBlackLabel() async =>
      (await _method.invokeMethod<bool>('isBlackLabel')) ?? false;

  /// Sets the paper feed space, used by [goToNextMark].
  Future<void> setFeedPaperSpace(int space) =>
      _method.invokeMethod<void>('setFeedPaperSpace', {'space': space});

  /// Returns the current feed paper space.
  Future<int> getFeedPaperSpace() async =>
      (await _method.invokeMethod<int>('getFeedPaperSpace')) ?? 0;

  /// Sets the length of paper rewound at boot, in tenths of a millimeter.
  Future<void> setUnwindPaperLen(int length) =>
      _method.invokeMethod<void>('setUnwindPaperLen', {'length': length});

  /// Returns the current unwind paper length.
  Future<int> getUnwindPaperLen() async =>
      (await _method.invokeMethod<int>('getUnwindPaperLen')) ?? 0;

  // ---- commands (added to the print buffer) --------------------------------

  /// Queues a text line for printing.
  ///
  /// The command is buffered; call [start] to actually print.
  Future<void> printText(
    String text, {
    PrintAlign align = PrintAlign.left,
    FontSize fontSize = FontSize.middle,
    bool bold = false,
    bool underline = false,
  }) {
    return _method.invokeMethod<void>('printText', {
      'text': text,
      'align': align.value,
      'fontSize': fontSize.value,
      'bold': bold,
      'underline': underline,
    });
  }

  /// Queues a 1D barcode for printing.
  ///
  /// [content] format must match [type] (e.g. EAN-13 expects 13 digits).
  /// [height] is in dots; [unitWidth] controls the bar width.
  Future<void> printBarcode(
    String content, {
    BarCodeType type = BarCodeType.code128,
    HriPosition hri = HriPosition.below,
    int height = 3,
    int unitWidth = 3,
  }) {
    return _method.invokeMethod<void>('printBarcode', {
      'type': type.value,
      'content': content,
      'hri': hri.value,
      'height': height,
      'unitWidth': unitWidth,
    });
  }

  /// Queues a QR code for printing.
  ///
  /// [size] is the side length of the QR module square in dots.
  Future<void> printQr(
    String content, {
    PrintAlign align = PrintAlign.center,
    int size = 384,
  }) {
    return _method.invokeMethod<void>('printQr', {
      'content': content,
      'align': align.value,
      'size': size,
    });
  }

  /// Queues a bitmap for printing, read from a file path on the device's
  /// filesystem. The native service must be able to read [path].
  Future<void> printBitmapPath(String path,
      {PrintAlign align = PrintAlign.center}) {
    return _method.invokeMethod<void>('printBitmapPath', {
      'path': path,
      'align': align.value,
    });
  }

  /// Queues a bitmap for printing, given its raw encoded bytes (PNG/JPEG).
  Future<void> printBitmapBytes(Uint8List bytes,
      {PrintAlign align = PrintAlign.center}) {
    return _method.invokeMethod<void>('printBitmapBytes', {
      'bytes': bytes,
      'align': align.value,
    });
  }

  /// Advances the paper by [lines] line feeds.
  Future<void> lineFeed(int lines) =>
      _method.invokeMethod<void>('lineFeed', {'lines': lines});

  /// Sets the feed paper space and triggers a feed to the next black mark.
  ///
  /// Used in label-paper mode to stop the paper between labels.
  /// Combines `setFeedPaperSpace` and `start` in a single call.
  Future<void> goToNextMark({int feedSpace = 1000}) =>
      _method.invokeMethod<void>('goToNextMark', {'feedSpace': feedSpace});
}
