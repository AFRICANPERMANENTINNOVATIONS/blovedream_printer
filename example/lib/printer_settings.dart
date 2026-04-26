import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted printer preferences. Wraps SharedPreferences so callers don't
/// have to deal with serialization, and applies the values to the printer in
/// the right order.
class PrinterSettings {
  PrinterSettings._(this._prefs);

  static const _kDensity = 'printer.density';
  static const _kFontSize = 'printer.fontSize';
  static const _kBold = 'printer.bold';
  static const _kUnderline = 'printer.underline';
  static const _kLineSpacing = 'printer.lineSpacing';
  static const _kFeedPaperSpace = 'printer.feedPaperSpace';
  static const _kUnwindPaperLen = 'printer.unwindPaperLen';
  static const _kBlackLabel = 'printer.blackLabel';

  final SharedPreferences _prefs;

  static Future<PrinterSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterSettings._(prefs);
  }

  Density get density =>
      Density.values.firstWhere((d) => d.value == (_prefs.getInt(_kDensity) ?? Density.middle.value),
          orElse: () => Density.middle);

  Future<void> setDensity(Density value) =>
      _prefs.setInt(_kDensity, value.value);

  FontSize get fontSize => FontSize.values.firstWhere(
      (f) => f.value == (_prefs.getInt(_kFontSize) ?? FontSize.middle.value),
      orElse: () => FontSize.middle);

  Future<void> setFontSize(FontSize value) =>
      _prefs.setInt(_kFontSize, value.value);

  bool get bold => _prefs.getBool(_kBold) ?? false;
  Future<void> setBold(bool value) => _prefs.setBool(_kBold, value);

  bool get underline => _prefs.getBool(_kUnderline) ?? false;
  Future<void> setUnderline(bool value) => _prefs.setBool(_kUnderline, value);

  double get lineSpacing => _prefs.getDouble(_kLineSpacing) ?? 1.0;
  Future<void> setLineSpacing(double value) =>
      _prefs.setDouble(_kLineSpacing, value);

  int get feedPaperSpace => _prefs.getInt(_kFeedPaperSpace) ?? 1000;
  Future<void> setFeedPaperSpace(int value) =>
      _prefs.setInt(_kFeedPaperSpace, value);

  int get unwindPaperLen => _prefs.getInt(_kUnwindPaperLen) ?? 30;
  Future<void> setUnwindPaperLen(int value) =>
      _prefs.setInt(_kUnwindPaperLen, value);

  bool get blackLabel => _prefs.getBool(_kBlackLabel) ?? false;
  Future<void> setBlackLabel(bool value) => _prefs.setBool(_kBlackLabel, value);

  /// Pushes every persisted value to the printer. Call once after `open()`.
  Future<void> applyTo(BlovedreamPrinter printer) async {
    await printer.setDensity(density);
    await printer.setFontSize(fontSize);
    await printer.setBold(bold);
    await printer.setUnderline(underline);
    await printer.setLineSpacing(lineSpacing);
    await printer.setFeedPaperSpace(feedPaperSpace);
    await printer.setUnwindPaperLen(unwindPaperLen);
    await printer.setBlackLabel(blackLabel);
  }
}
