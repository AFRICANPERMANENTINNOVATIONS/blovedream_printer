import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter/material.dart';

import 'printer_settings.dart';

/// Label-paper workflow page.
///
/// On Blovedream label paper, every label is separated by a printed black
/// mark on the back. The print manager can detect that mark and stop the
/// paper exactly between two labels:
///
/// 1. `setUnwindPaperLen(distance)` once at boot — how much paper the device
///    rewinds before printing (in tenths of mm).
/// 2. `setBlackLabel(true)` — enables mark detection.
/// 3. Add commands for one label.
/// 4. `goToNextMark(feedSpace)` — feeds to the next mark and triggers print.
class LabelModePage extends StatefulWidget {
  const LabelModePage({super.key, required this.settings});
  final PrinterSettings settings;

  @override
  State<LabelModePage> createState() => _LabelModePageState();
}

class _LabelModePageState extends State<LabelModePage> {
  final BlovedreamPrinter _printer = BlovedreamPrinter.instance;

  late final TextEditingController _unwindCtrl =
      TextEditingController(text: widget.settings.unwindPaperLen.toString());
  late final TextEditingController _feedCtrl =
      TextEditingController(text: widget.settings.feedPaperSpace.toString());

  /// Label content.
  final TextEditingController _line1Ctrl =
      TextEditingController(text: 'Label test');
  final TextEditingController _line2Ctrl =
      TextEditingController(text: 'This is a line of test labels');
  final TextEditingController _barcodeCtrl =
      TextEditingController(text: '123456789012');

  bool _busy = false;
  String _status = 'Idle';

  @override
  void dispose() {
    _unwindCtrl.dispose();
    _feedCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _calibrate() async {
    final unwind =
        int.tryParse(_unwindCtrl.text.trim()) ?? widget.settings.unwindPaperLen;
    final feed =
        int.tryParse(_feedCtrl.text.trim()) ?? widget.settings.feedPaperSpace;
    await _wrap(() async {
      await widget.settings.setUnwindPaperLen(unwind);
      await widget.settings.setFeedPaperSpace(feed);
      await widget.settings.setBlackLabel(true);
      await _printer.setUnwindPaperLen(unwind);
      await _printer.setFeedPaperSpace(feed);
      await _printer.setBlackLabel(true);
    }, 'Calibrated · unwind=$unwind, feed=$feed');
  }

  Future<void> _disableLabelMode() async {
    await _wrap(() async {
      await widget.settings.setBlackLabel(false);
      await _printer.setBlackLabel(false);
    }, 'Label mode OFF');
  }

  Future<void> _printTextLabel() async {
    final feed = int.tryParse(_feedCtrl.text.trim()) ?? 1000;
    await _wrap(() async {
      await _printer.setBlackLabel(true);
      await _printer.lineFeed(2);
      await _printer.printText(
        _line1Ctrl.text,
        align: PrintAlign.center,
        fontSize: FontSize.large,
        bold: true,
      );
      await _printer.printText(
        _line2Ctrl.text,
        align: PrintAlign.center,
        fontSize: FontSize.middle,
      );
      await _printer.goToNextMark(feedSpace: feed);
    }, 'Text label sent (feed=$feed)');
  }

  Future<void> _printBarcodeLabel() async {
    final feed = int.tryParse(_feedCtrl.text.trim()) ?? 1000;
    final content = _barcodeCtrl.text.trim();
    if (content.isEmpty) {
      setState(() => _status = 'Barcode content is empty');
      return;
    }
    await _wrap(() async {
      await _printer.setBlackLabel(true);
      await _printer.lineFeed(2);
      await _printer.printBarcode(
        content,
        type: BarCodeType.code128,
        hri: HriPosition.below,
      );
      await _printer.goToNextMark(feedSpace: feed);
    }, 'Barcode label sent');
  }

  Future<void> _printTemplateLabel() async {
    final feed = int.tryParse(_feedCtrl.text.trim()) ?? 1000;
    await _wrap(() async {
      await _printer.setBlackLabel(true);
      await _printer.lineFeed(1);
      await _printer.printText(
        _line1Ctrl.text,
        align: PrintAlign.center,
        fontSize: FontSize.large,
        bold: true,
      );
      await _printer.printText(
        _line2Ctrl.text,
        align: PrintAlign.left,
        fontSize: FontSize.small,
      );
      await _printer.printBarcode(
        _barcodeCtrl.text.isEmpty ? '0000000000' : _barcodeCtrl.text,
        type: BarCodeType.code128,
        hri: HriPosition.below,
      );
      await _printer.goToNextMark(feedSpace: feed);
    }, 'Template label sent');
  }

  Future<void> _wrap(Future<void> Function() body, String okMsg) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Working…';
    });
    try {
      await body();
      setState(() => _status = okMsg);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label mode'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_status, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Calibration',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _unwindCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Unwind paper length (1/10 mm)',
                        helperText: 'Paper rewound at boot. Try 30 (≈3 mm).',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _feedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Feed paper space',
                        helperText: 'Max distance to seek the black mark.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _calibrate,
                          child: const Text('Apply & enable'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _disableLabelMode,
                          child: const Text('Disable'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Label content',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _line1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _line2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (CODE128)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Print',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _printTextLabel,
                      child: const Text('Print 1 text label'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _printBarcodeLabel,
                      child: const Text('Print 1 barcode label'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _printTemplateLabel,
                      child: const Text('Print 1 template label'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
