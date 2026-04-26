import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter/material.dart';

import 'printer_settings.dart';

/// Lets the user edit and persist printer-wide preferences. Every change is
/// pushed to the printer immediately and saved to disk.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});
  final PrinterSettings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BlovedreamPrinter _printer = BlovedreamPrinter.instance;
  late final TextEditingController _feedCtrl =
      TextEditingController(text: widget.settings.feedPaperSpace.toString());
  late final TextEditingController _unwindCtrl =
      TextEditingController(text: widget.settings.unwindPaperLen.toString());

  String _status = 'Idle';

  @override
  void dispose() {
    _feedCtrl.dispose();
    _unwindCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply(Future<void> Function() body, String label) async {
    try {
      await body();
      setState(() => _status = '$label saved');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer settings'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Density (darkness)'),
          DropdownButtonFormField<Density>(
            initialValue: s.density,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: Density.values
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('${d.name}  (${d.value})'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {});
              _apply(() async {
                await s.setDensity(v);
                await _printer.setDensity(v);
              }, 'Density');
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle('Font size'),
          DropdownButtonFormField<FontSize>(
            initialValue: s.fontSize,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: FontSize.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text('${f.name}  (${f.value})'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {});
              _apply(() async {
                await s.setFontSize(v);
                await _printer.setFontSize(v);
              }, 'Font size');
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Bold'),
            value: s.bold,
            onChanged: (v) {
              setState(() {});
              _apply(() async {
                await s.setBold(v);
                await _printer.setBold(v);
              }, 'Bold');
            },
          ),
          SwitchListTile(
            title: const Text('Underline'),
            value: s.underline,
            onChanged: (v) {
              setState(() {});
              _apply(() async {
                await s.setUnderline(v);
                await _printer.setUnderline(v);
              }, 'Underline');
            },
          ),
          SwitchListTile(
            title: const Text('Black-mark (label) mode'),
            subtitle: const Text(
                'Enable for label paper so the printer stops between labels.'),
            value: s.blackLabel,
            onChanged: (v) {
              setState(() {});
              _apply(() async {
                await s.setBlackLabel(v);
                await _printer.setBlackLabel(v);
              }, 'Label mode');
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle('Line spacing'),
          Slider(
            value: s.lineSpacing,
            min: 0.0,
            max: 5.0,
            divisions: 50,
            label: s.lineSpacing.toStringAsFixed(1),
            onChanged: (v) {
              setState(() {});
              s.setLineSpacing(v);
            },
            onChangeEnd: (v) => _apply(() async {
              await s.setLineSpacing(v);
              await _printer.setLineSpacing(v);
            }, 'Line spacing'),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Feed paper space'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _feedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  helperText: 'Used by goToNextMark / label print.',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(_feedCtrl.text.trim());
                if (v == null) return;
                _apply(() async {
                  await s.setFeedPaperSpace(v);
                  await _printer.setFeedPaperSpace(v);
                }, 'Feed paper space');
              },
              child: const Text('Save'),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('Unwind paper length (1/10 mm)'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _unwindCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(_unwindCtrl.text.trim());
                if (v == null) return;
                _apply(() async {
                  await s.setUnwindPaperLen(v);
                  await _printer.setUnwindPaperLen(v);
                }, 'Unwind length');
              },
              child: const Text('Save'),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
