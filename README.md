# blovedream_printer

[![pub package](https://img.shields.io/pub/v/blovedream_printer.svg)](https://pub.dev/packages/blovedream_printer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Flutter plugin for **Blovedream (BLD)** Android terminals (PDAs, POS handhelds)
with a built-in thermal / label printer. Wraps the OEM `android.bld.PrintManager`
service through Java reflection — no proprietary jar to embed.

> ⚠️ Works only on devices that ship the Blovedream printer service. The
> system property `ro.blovedream_support_print` must be exposed by the
> firmware. On any other Android device, `open()` throws a
> `PlatformException(BLD_ERROR, ...)`.

## Features

- Open / close / start / reset the printer
- Print **text** (alignment, font size, bold, underline)
- Print **1D barcodes**: UPC-A/E, EAN-8/13, CODE39, CODE93, CODE128, ITF, CODABAR — with HRI position
- Print **QR codes** (alignment, size)
- Print **bitmaps** from a file path *or* raw bytes (`Uint8List`)
- **Line feed** (n lines)
- **Label-paper mode** (black-mark detection, feed-to-next-mark)
- Configure: density, font size, line spacing, reverse, underline
- Read the firmware version
- Stream of print events (`onPrintCallback`, `onVersion`)

## Platform support

| Platform | Status     |
|----------|------------|
| Android  | ✅ supported (Blovedream firmware required) |
| iOS / web / desktop | ❌ not applicable (hardware-bound) |

## Installation

```yaml
dependencies:
  blovedream_printer: ^0.1.1
```

```bash
flutter pub get
```

## Permissions

The plugin itself does **not** require any Android permission — the BLD print
service is a system service the OEM exposes to all apps, and bitmap data is
either passed in-memory (`Uint8List`) or via a file path the consumer app
already has access to.

If your app passes file paths from the gallery (e.g. via `image_picker`), add
the relevant media-read permissions to your own `AndroidManifest.xml`:

```xml
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>
```

## Usage

### Quick start

```dart
import 'package:blovedream_printer/blovedream_printer.dart';

final printer = BlovedreamPrinter.instance;

// Listen to print results & firmware version.
printer.events.listen((event) {
  if (event is PrintCallbackEvent) {
    debugPrint('print result: ${event.errorCode}');
  } else if (event is PrinterVersionEvent) {
    debugPrint('firmware: ${event.version}');
  }
});

await printer.open();
await printer.setFontSize(FontSize.middle);

await printer.printText('Hello Blovedream!', align: PrintAlign.center);
await printer.printQr('https://example.com');
await printer.lineFeed(3);

await printer.start();   // commits the queued commands
```

### Label paper (black-mark detection)

```dart
// Configure once at boot:
await printer.setUnwindPaperLen(30);   // 3 mm
await printer.setBlackLabel(true);

// For each label:
await printer.lineFeed(2);
await printer.printText(
  'Order #12345',
  align: PrintAlign.center,
  fontSize: FontSize.large,
  bold: true,
);
await printer.printBarcode(
  'AB-12345',
  type: BarCodeType.code128,
  hri: HriPosition.below,
);
await printer.goToNextMark(feedSpace: 1000);   // feeds to next black mark
```

### Image printing

```dart
// From a file path (e.g. the gallery)
await printer.printBitmapPath('/path/to/image.png', align: PrintAlign.center);
await printer.start();

// From raw bytes (PNG/JPEG)
final Uint8List bytes = await rootBundle
    .load('assets/logo.png')
    .then((b) => b.buffer.asUint8List());
await printer.printBitmapBytes(bytes);
await printer.start();
```

## Error codes

`PrintCallbackEvent.errorCode` is a [`PrinterErrorCode`](https://pub.dev/documentation/blovedream_printer/latest/blovedream_printer/PrinterErrorCode.html)
enum. The most common values:

| Code | Meaning |
|------|---------|
| `noError` | Success |
| `printNoPaper` | Out of paper |
| `printHot` | Print head overheated |
| `devNoBattery` | Battery too low |
| `devNotOpen` | `open()` was not called or has failed |
| `dataInvalid` | Malformed command |

The full list is in `lib/src/enums.dart`.

## How it works

The Blovedream firmware exposes a system service whose AIDL is
`android.bld.PrintManager`. That class is **not** part of the AOSP SDK, so we
can't link it at compile time on a regular machine. Instead, the Android side
of this plugin resolves every method via `java.lang.reflect.Method` at runtime
and proxies the listener interface (`android.bld.print.aidl.PrinterBinderListener`)
with `java.lang.reflect.Proxy`. This means:

- The plugin compiles on any machine, no proprietary jar needed.
- On a non-Blovedream device, `open()` fails fast with a clear error.

## Example

A complete example covering text, barcode, QR, image, and label-mode workflows
is available in the [`example/`](example) folder of the repository.

## Contributing

Issues and pull requests are welcome on
[GitHub](https://github.com/permanentinnovations/blovedream_printer).

## License

MIT — see [LICENSE](LICENSE).
