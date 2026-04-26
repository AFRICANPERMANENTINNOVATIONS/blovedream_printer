import 'enums.dart';

/// Base class for events emitted by [BlovedreamPrinter.events].
///
/// Two concrete subtypes are emitted:
///  - [PrintCallbackEvent] — result of a print job
///  - [PrinterVersionEvent] — firmware version, emitted once after attach
sealed class PrintEvent {
  const PrintEvent();
}

/// Emitted when the printer reports the result of a print job.
class PrintCallbackEvent extends PrintEvent {
  /// Builds a callback event from a [PrinterErrorCode].
  const PrintCallbackEvent(this.errorCode);

  /// The result code returned by the printer.
  final PrinterErrorCode errorCode;

  /// Whether the job completed without error.
  bool get isSuccess => errorCode == PrinterErrorCode.noError;

  @override
  String toString() => 'PrintCallbackEvent(${errorCode.name})';
}

/// Emitted once after the listener is attached, carrying the firmware version.
class PrinterVersionEvent extends PrintEvent {
  /// Builds a version event.
  const PrinterVersionEvent(this.version);

  /// Firmware version string reported by the printer.
  final String version;

  @override
  String toString() => 'PrinterVersionEvent($version)';
}
