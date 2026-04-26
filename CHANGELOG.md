## 0.1.1

- Rename `Align` enum to `PrintAlign` to avoid collision with Flutter's
  `Align` widget. **Breaking** for consumers of 0.1.0.
- Drop unused `plugin_platform_interface` dependency.
- Add full dartdoc on all public APIs.
- Add LICENSE (MIT).
- Expand README with permission, label-mode and error-code sections.

## 0.1.0

- Initial release.
- Wraps `android.bld.PrintManager` via reflection (no proprietary jar required).
- Text, barcode, QR, bitmap (path or bytes), line feed.
- Density, font size, bold, underline, reverse, line spacing, black-mark mode.
- Print event stream (`onPrintCallback`, `onVersion`).
