import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;

// Web-only download helper
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() {
    runApp(const SignatureApp());
}

class SignatureApp extends StatelessWidget {
    const SignatureApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Digital Signature Pad',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
            ),
            home: const SignatureScreen(),
        );
    }
}

class SignatureScreen extends StatefulWidget {
    const SignatureScreen({super.key});

    @override
    State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
    int _selectedIndex = 1; // 0: Home, 1: Signature, 2: Settings

    // Store all submitted signature data in memory
    final List<Map<String, String>> _submittedData = [];

    void _addSignatureData(Map<String, String> data) {
        setState(() {
            _submittedData.add(data);
        });
    }

    void _downloadAllCsv() async {
        if (_submittedData.isEmpty) return;
        final csvHeader = 'Name,Email,Timestamp,SignatureBase64';
        final csvRows = _submittedData.map((row) => '"${row['name']}","${row['email']}","${row['timestamp']}","${row['signatureBase64']}"').join('\n');
        final csvContent = '$csvHeader\n$csvRows';
        final String safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final String fileName = 'dashboard-signatures-$safeTimestamp.csv';
        if (kIsWeb) {
            final blob = html.Blob([csvContent]);
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement(href: url)
                ..setAttribute('download', fileName)
                ..click();
            html.Url.revokeObjectUrl(url);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV download started (web)')),
            );
        } else {
            final Directory dir = await getApplicationDocumentsDirectory();
            final File csvFile = File('${dir.path}/$fileName');
            await csvFile.writeAsString(csvContent, flush: true);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dashboard CSV saved to ${csvFile.path}')),
            );
        }
    }

    void _onItemTapped(int index) {
        setState(() {
            _selectedIndex = index;
        });
    }

    @override
    Widget build(BuildContext context) {
        final List<Widget> _pages = <Widget>[
            HomePage(
                submittedData: _submittedData,
                onDownloadCsv: _downloadAllCsv,
            ),
            SignaturePadPage(
                onSubmit: _addSignatureData,
            ),
            const SettingsPage(),
        ];
        return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.edit),
                        label: 'Signature',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                    ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.blue,
                onTap: _onItemTapped,
            ),
        );
    }
}

// SignaturePadPage is the original signature UI, refactored as a separate widget
class SignaturePadPage extends StatefulWidget {
    final void Function(Map<String, String>)? onSubmit;
    const SignaturePadPage({Key? key, this.onSubmit}) : super(key: key);

    @override
    State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final GlobalKey _signatureKey = GlobalKey();
    final List<Offset?> _points = <Offset?>[];
    String _status = 'Draw on the white pad above 👆';

    bool get _hasSignature => _points.where((p) => p != null).length > 2;

    @override
    void dispose() {
        _nameController.dispose();
        _emailController.dispose();
        super.dispose();
    }

    void _clearSignature() {
        setState(() {
            _points.clear();
            _status = 'Canvas cleared. Points: 0';
        });
    }

    void _showMessage(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
        );
    }

    Future<Uint8List> _captureSignaturePng() async {
        RenderRepaintBoundary boundary =
                _signatureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData!.buffer.asUint8List();
    }

    Future<void> _submitSignature() async {
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();

        if (name.isEmpty || email.isEmpty) {
            setState(() {
                _status = 'Validation failed: Name and email are required.';
            });
            _showMessage('Please enter both your name and email.');
            return;
        }

        if (!_hasSignature) {
            setState(() {
                _status = 'Validation failed: Signature is required.';
            });
            _showMessage('Please draw a signature before submitting.');
            return;
        }

        final bool? approved = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: const Text('Confirm Signature'),
                    content: const Text(
                        'Is this signature good? Tap Approve to save PNG and CSV.',
                    ),
                    actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Edit'),
                        ),
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Approve'),
                        ),
                    ],
                );
            },
        );

        if (approved != true) {
            setState(() {
                _status = 'Signature rejected. Please edit and try again.';
            });
            return;
        }

        try {
            final Uint8List pngBytes = await _captureSignaturePng();
            final String timestamp = DateTime.now().toIso8601String();
            final String safeTimestamp = timestamp.replaceAll(':', '-');
            final String fileName = 'digital-signature-$safeTimestamp.png';

            if (kIsWeb) {
                final blob = html.Blob([pngBytes]);
                final url = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.AnchorElement(href: url)
                  ..setAttribute('download', fileName)
                  ..click();
                html.Url.revokeObjectUrl(url);
                _showMessage('Signature PNG download started (web)');
            } else {
                final Directory dir = await getApplicationDocumentsDirectory();
                final File pngFile = File('${dir.path}/$fileName');
                await pngFile.writeAsBytes(pngBytes, flush: true);
                _showMessage('Signature PNG saved to ${dir.path}');
            }

            final String signatureBase64 = base64Encode(pngBytes);

            // Save to dashboard (in-memory)
            if (widget.onSubmit != null) {
                widget.onSubmit!({
                    'name': name,
                    'email': email,
                    'timestamp': timestamp,
                    'signatureBase64': signatureBase64,
                });
            }

            setState(() {
                _status = 'Signature saved and sent to dashboard!';
            });
        } catch (e) {
            setState(() {
                _status = 'Error saving files: $e';
            });
            _showMessage('Failed to save: $e');
        }
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                        Color(0xFF9EE37D),
                        Color(0xFF3CB6E3),
                    ],
                ),
            ),
            child: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                            const SizedBox(height: 12),
                            Center(
                                child: Image.asset(
                                    'assets/images/icon.png',
                                    width: 70,
                                    height: 70,
                                ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                'GAC Qualivaxx',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                ),
                            ),
                            const SizedBox(height: 18),
                            RepaintBoundary(
                                key: _signatureKey,
                                child: Container(
                                    height: 280,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black54, width: 2),
                                    ),
                                    child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (DragStartDetails details) {
                                            setState(() {
                                                _points.add(details.localPosition);
                                            });
                                        },
                                        onPanUpdate: (DragUpdateDetails details) {
                                            setState(() {
                                                _points.add(details.localPosition);
                                            });
                                        },
                                        onPanEnd: (_) {
                                            setState(() {
                                                _points.add(null);
                                            });
                                        },
                                        child: MouseRegion(
                                            cursor: SystemMouseCursors.cell,
                                            child: CustomPaint(
                                                painter: SignaturePainter(_points),
                                                child: const SizedBox.expand(),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                                alignment: Alignment.center,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                        TextField(
                                            controller: _nameController,
                                            decoration: const InputDecoration(
                                                labelText: 'Your Name',
                                                border: OutlineInputBorder(),
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                                labelText: 'Your Email',
                                                border: OutlineInputBorder(),
                                            ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                            children: <Widget>[
                                                Expanded(
                                                    child: ElevatedButton(
                                                        onPressed: _clearSignature,
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            foregroundColor: Colors.white,
                                                        ),
                                                        child: const Text('Clear'),
                                                    ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: ElevatedButton(
                                                        onPressed: _submitSignature,
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                            foregroundColor: Colors.white,
                                                        ),
                                                        child: const Text('Submit & Save Signature'),
                                                    ),
                                                ),
                                            ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (_status.isNotEmpty)
                                            Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(_status),
                                            ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

class SignaturePainter extends CustomPainter {
    SignaturePainter(this.points);

    final List<Offset?> points;

    @override
    void paint(Canvas canvas, Size size) {
        for (int i = 0; i < points.length - 1; i++) {
            final Offset? current = points[i];
            final Offset? next = points[i + 1];
            if (current != null && next != null) {
                final paint = Paint()
                    ..color = Colors.black87
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3.0;
                canvas.drawLine(current, next, paint);
            }
        }
    }

    @override
    bool shouldRepaint(covariant SignaturePainter oldDelegate) {
        return true;
    }
}

class HomePage extends StatelessWidget {
    final List<Map<String, String>> submittedData;
    final VoidCallback? onDownloadCsv;
    const HomePage({Key? key, required this.submittedData, this.onDownloadCsv}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (submittedData.isEmpty)
                        const Text('No signatures submitted yet.'),
                    if (submittedData.isNotEmpty)
                        Expanded(
                            child: ListView.builder(
                                itemCount: submittedData.length,
                                itemBuilder: (context, index) {
                                    final row = submittedData[index];
                                    return Card(
                                        child: ListTile(
                                            title: Text(row['name'] ?? ''),
                                            subtitle: Text('Email: ${row['email'] ?? ''}\nTime: ${row['timestamp'] ?? ''}'),
                                            isThreeLine: true,
                                            trailing: Icon(Icons.check_circle, color: Colors.green),
                                        ),
                                    );
                                },
                            ),
                        ),
                    const SizedBox(height: 16),
                    if (submittedData.isNotEmpty)
                        Center(
                            child: ElevatedButton.icon(
                                onPressed: onDownloadCsv,
                                icon: const Icon(Icons.download),
                                label: const Text('Download All as CSV'),
                            ),
                        ),
                ],
            ),
        );
    }
}

class SettingsPage extends StatelessWidget {
    const SettingsPage({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text(
                'Settings Page (coming soon)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        );
    }
}
