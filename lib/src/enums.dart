/// Constants extracted from `com.example.lc_print_sdk.PrintConfig`.
library;

/// Horizontal alignment of a printed line or block.
///
/// Maps to the `align` argument of the native `addText`, `addQRCode`,
/// `addImage` and `addImageFile` methods.
enum PrintAlign {
  /// Align to the left edge of the paper.
  left(1),

  /// Center on the paper.
  center(2),

  /// Align to the right edge of the paper.
  right(3);

  const PrintAlign(this.value);

  /// Numeric value passed to the native API.
  final int value;
}

/// Barcode symbologies supported by the BLD print manager.
enum BarCodeType {
  /// UPC-A — 12-digit numeric.
  upcA(0x41),

  /// UPC-E — 6-digit numeric.
  upcE(0x42),

  /// EAN-13 — 13-digit numeric.
  ean13(0x43),

  /// EAN-8 — 8-digit numeric.
  ean8(0x44),

  /// CODE 39 — alphanumeric.
  code39(0x45),

  /// Interleaved 2 of 5 — numeric, even number of digits.
  itf(0x46),

  /// CODABAR — numeric + a few symbols.
  codabar(0x47),

  /// CODE 93 — denser variant of CODE 39.
  code93(0x48),

  /// CODE 128 — full ASCII, the most flexible 1D symbology.
  code128(0x49);

  const BarCodeType(this.value);

  /// Numeric value passed to the native API.
  final int value;
}

/// Font size, mapped to the `setFontSize(int)` argument of the native API.
enum FontSize {
  /// Smallest available size (level 1).
  small(1),

  /// Slightly bigger than [small].
  xSmall(2),

  /// Default font size.
  middle(3),

  /// Slightly bigger than [middle].
  xMiddle(4),

  /// Big font.
  large(5),

  /// Bigger than [large].
  xLarge(6),

  /// Very large font.
  superSize(7),

  /// Largest available size.
  xSuper(8);

  const FontSize(this.value);

  /// Numeric value passed to the native API.
  final int value;
}

/// Print density / darkness. The native API exposes 10 levels (1–10).
///
/// The original SDK's `printConcentration` divides this by 4 and adds 1; this
/// plugin exposes the raw 1–10 scale so callers don't have to think about
/// that translation.
enum Density {
  /// Lightest setting.
  small(1),

  /// One step darker than [small].
  xSmall(2),

  /// Default density.
  middle(3),

  /// One step darker than [middle].
  xMiddle(4),

  /// Darker than [middle].
  large(5),

  /// Even darker.
  xLarge(6),

  /// Very dark.
  xxLarge(7),

  /// Darker than [xxLarge].
  superDensity(8),

  /// Near-maximum darkness.
  xSuper(9),

  /// Darkest setting.
  xxSuper(10);

  const Density(this.value);

  /// Numeric value passed to the native API.
  final int value;
}

/// Position of the human-readable interpretation (HRI) text under barcodes.
enum HriPosition {
  /// No human-readable text printed.
  none(1),

  /// HRI text printed above the barcode.
  above(2),

  /// HRI text printed below the barcode.
  below(3),

  /// HRI text printed both above and below.
  both(4);

  const HriPosition(this.value);

  /// Numeric value passed to the native API.
  final int value;
}

/// Result codes reported by the printer through `onPrintCallback`.
///
/// `noError` (0) means the job succeeded; any other value indicates a
/// hardware or command error.
enum PrinterErrorCode {
  /// Print job completed successfully.
  noError(0x00),

  /// The printer is busy with another job.
  devIsBusy(0x01),

  /// The print head temperature is too high.
  printHot(0x02),

  /// The printer is out of paper.
  printNoPaper(0x03),

  /// Battery level is too low to print.
  devNoBattery(0x04),

  /// Paper feed mechanism failed.
  devFeed(0x05),

  /// Generic print device failure.
  devPrint(0x06),

  /// Failed to detect a black mark.
  devBmark(0x07),

  /// `open()` was not called, or it failed.
  devNotOpen(0x10),

  /// No data was queued for printing.
  noData(0x11),

  /// One of the queued commands carried invalid data.
  dataInvalid(0x12),

  /// Unknown command.
  cmd(0x13),

  /// Density value is out of range.
  grayInvalid(0x14),

  /// Failure while rendering text.
  printText(0xa0),

  /// Failure while rendering a bitmap.
  printBitmap(0xa1),

  /// Failure while rendering a barcode.
  printBarcode(0xa2),

  /// Failure while rendering a QR code.
  printQrcode(0xa3),

  /// Bitmap is wider than the paper.
  printBitmapWidthOverflow(0xa4),

  /// Invalid input data.
  dataInput(0xa5),

  /// One of the arguments was invalid.
  printIllegalArgument(0xa6),

  /// MAC verification failed (for signed jobs).
  printDataMac(0xa7),

  /// A previous result is still pending.
  resultExist(0xa8),

  /// Operation timed out.
  timeOut(0xa9),

  /// Unknown / unmapped error.
  unknown(0xff);

  const PrinterErrorCode(this.value);

  /// Numeric value reported by the native API.
  final int value;

  /// Returns the [PrinterErrorCode] matching [value], or [unknown] if none
  /// matches.
  static PrinterErrorCode fromValue(int value) {
    for (final code in PrinterErrorCode.values) {
      if (code.value == value) return code;
    }
    return PrinterErrorCode.unknown;
  }
}

/// State queries supported by the underlying API.
///
/// Currently exposed for reference only; the plugin does not yet wrap
/// state-query commands.
enum StateType {
  /// Run all state checks.
  all(1),

  /// Whether the printer is currently busy.
  busy(2),

  /// Print-head temperature.
  temp(3),

  /// Whether paper is loaded.
  paper(4),

  /// Paper-feed status.
  feed(5),

  /// Print engine status.
  print(6),

  /// Black-mark detection status.
  bmask(7);

  const StateType(this.value);

  /// Numeric value passed to the native API.
  final int value;
}
