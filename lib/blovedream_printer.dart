/// Flutter plugin for Blovedream (BLD) Android terminals with a built-in
/// thermal / label printer.
///
/// Wraps the OEM `android.bld.PrintManager` system service via reflection.
/// See [BlovedreamPrinter] for the main entry point.
library;

export 'src/enums.dart';
export 'src/printer.dart';
export 'src/printer_event.dart';
