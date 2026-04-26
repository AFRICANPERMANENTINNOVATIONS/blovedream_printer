import 'dart:io';

import 'package:blovedream_printer/blovedream_printer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'label_mode_page.dart';
import 'printer_settings.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await PrinterSettings.load();
  runApp(ExampleApp(settings: settings));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.settings});
  final PrinterSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blovedream Printer Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: HomePage(settings: settings),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.settings});
  final PrinterSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BlovedreamPrinter _printer = BlovedreamPrinter.instance;
  String _status = 'Idle';
  String? _firmware;

  @override
  void initState() {
    super.initState();
    _printer.events.listen((event) {
      setState(() {
        if (event is PrintCallbackEvent) {
          _status = 'Result: ${event.errorCode.name}';
        } else if (event is PrinterVersionEvent) {
          _firmware = event.version;
        }
      });
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _printer.open();
      await widget.settings.applyTo(_printer);
      setState(() => _status = 'Printer opened, settings applied');
    } catch (e) {
      setState(() => _status = 'open() failed: $e');
    }
  }

  Future<void> _run(Future<void> Function() body) async {
    try {
      await body();
      await _printer.start();
      setState(() => _status = 'Job sent');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blovedream Printer'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsPage(settings: widget.settings),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Label mode',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LabelModePage(settings: widget.settings),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _firmware == null ? _status : '$_status · fw: $_firmware',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Thermal text',
            children: [
              FilledButton(
                onPressed: () => _run(() async {
                  await _printer.printText(
                    'Hello Blovedream!',
                    align: PrintAlign.center,
                    fontSize: FontSize.large,
                    bold: true,
                  );
                  await _printer.lineFeed(2);
                }),
                child: const Text('Print "Hello Blovedream!"'),
              ),
              OutlinedButton(
                onPressed: () => _run(() async {
                  await _printer.printText('Left aligned', align: PrintAlign.left);
                  await _printer.printText('Center aligned',
                      align: PrintAlign.center);
                  await _printer.printText('Right aligned',
                      align: PrintAlign.right);
                  await _printer.lineFeed(3);
                }),
                child: const Text('Print alignment sample'),
              ),
            ],
          ),
          _Section(
            title: 'Barcode',
            children: [
              FilledButton(
                onPressed: () => _run(() async {
                  await _printer.printBarcode(
                    '123456789012',
                    type: BarCodeType.code128,
                    hri: HriPosition.below,
                  );
                  await _printer.lineFeed(3);
                }),
                child: const Text('Print CODE128'),
              ),
            ],
          ),
          _Section(
            title: 'QR code',
            children: [
              FilledButton(
                onPressed: () => _run(() async {
                  await _printer.printQr(
                    'https://permanentinnovations.africa',
                    size: 384,
                  );
                  await _printer.lineFeed(3);
                }),
                child: const Text('Print QR code'),
              ),
            ],
          ),
          _Section(
            title: 'Image',
            children: [
              FilledButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 100,
                  );
                  if (picked == null) return;
                  if (Platform.isAndroid) {
                    await _run(() async {
                      await _printer.printBitmapPath(picked.path);
                      await _printer.lineFeed(3);
                    });
                  }
                },
                child: const Text('Pick & print image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
