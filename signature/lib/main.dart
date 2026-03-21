
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '_info_row.dart';
import 'web_download_helper.dart' if (dart.library.html) 'web_download_helper.dart' if (dart.library.io) 'web_download_helper_stub.dart';

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
    final csvHeader = 'Name,Position,Timestamp,SignatureBase64';
    final csvRows = _submittedData.map((row) => '"${row['name']}","${row['position']}","${row['timestamp']}","${row['signatureBase64']}"').join('\n');
    final csvContent = '$csvHeader\n$csvRows';
    final String safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final String fileName = 'dashboard-signatures-$safeTimestamp.csv';
    if (kIsWeb) {
      downloadFileWeb(csvContent, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV download started (web)')),
      );
    } else {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File csvFile = File('${dir.path}/$fileName');
      await csvFile.writeAsString(csvContent, flush: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dashboard CSV saved to \\${csvFile.path}')),
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
      const SignaturePadPage(),
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
  const SignaturePadPage({super.key});

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
    final TextEditingController _positionController = TextEditingController();
  late SignatureController _signatureController;
  String _status = 'Draw your signature on the pad above 👆';

  bool get _hasSignature => _signatureController.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3.0,
      penColor: Colors.black87,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    setState(() {
      _signatureController.clear();
      _status = 'Signature cleared';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Uint8List?> _captureSignaturePng() async {
    return await _signatureController.toPngBytes();
  }

  Future<void> _submitSignature() async {
    final String name = _nameController.text.trim();
    final String position = _positionController.text.trim();

    if (name.isEmpty || position.isEmpty) {
      setState(() {
        _status = 'Validation failed: Name and position are required.';
      });
      _showMessage('Please enter both your name and position.');
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
            'Is this signature good? Tap Approve to save PNG, Excel with hyperlink, and CSV.',
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
      final Uint8List? pngBytes = await _captureSignaturePng();
      if (pngBytes == null) {
        setState(() {
          _status = 'Failed to capture signature image.';
        });
        _showMessage('Failed to capture signature image.');
        return;
      }
      final String timestamp = DateTime.now().toIso8601String();
      final String safeTimestamp = timestamp.replaceAll(':', '-');
      final String pngFileName = 'digital-signature-$safeTimestamp.png';
      final String xlsxFileName = 'signature-$safeTimestamp.xlsx';

      if (kIsWeb) {
        // Download PNG
        downloadFileWeb(String.fromCharCodes(pngBytes), pngFileName);

        // For Excel on web, create bytes and download
        final xlsio.Workbook workbook = xlsio.Workbook();
        final xlsio.Worksheet sheet = workbook.worksheets[0];
        sheet.getRangeByName('A1').setText('Signature');
        // Use HYPERLINK formula so Excel will show a clickable link to the PNG filename
        sheet.getRangeByName('B1').setFormula('=HYPERLINK("$pngFileName","View Signature")');
        final List<int> xlsxBytes = workbook.saveAsStream();
        workbook.dispose();
        downloadFileWeb(String.fromCharCodes(Uint8List.fromList(xlsxBytes)), xlsxFileName);

        _showMessage('PNG and Excel downloaded (web)');
      } else {
        final Directory dir = await getApplicationDocumentsDirectory();
        final File pngFile = File('${dir.path}/$pngFileName');
        await pngFile.writeAsBytes(pngBytes, flush: true);

        // Create Excel with hyperlink to PNG
        final xlsio.Workbook workbook = xlsio.Workbook();
        final xlsio.Worksheet sheet = workbook.worksheets[0];
        sheet.getRangeByName('A1').setText('Signature for $name');
        // Use HYPERLINK formula with file URI so Excel can open the local file
        final fileUri = 'file:///${pngFile.path.replaceAll('\\', '/')}';
        sheet.getRangeByName('B1').setFormula('=HYPERLINK("$fileUri","View Signature")');
        final List<int> xlsxBytes = workbook.saveAsStream();
        workbook.dispose();

        final File xlsxFile = File('${dir.path}/$xlsxFileName');
        await xlsxFile.writeAsBytes(xlsxBytes, flush: true);

        _showMessage('PNG saved: ${pngFile.path}\nExcel saved: ${xlsxFile.path}');
      }

      final String signatureBase64 = base64Encode(pngBytes);

      // Find parent SignatureScreen state and add to dashboard
      final _SignatureScreenState? parentState = context.findAncestorStateOfType<_SignatureScreenState>();
      if (parentState != null) {
        parentState._addSignatureData({
          'name': name,
          'position': position,
          'timestamp': timestamp,
          'signatureBase64': signatureBase64,
        });
      }

      setState(() {
        _status = 'PNG, Excel (with hyperlink), and dashboard updated!';
      });

      _nameController.clear();
      _positionController.clear();
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
              Signature(
                controller: _signatureController,
                height: 280,
                backgroundColor: Colors.white,
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
                      controller: _positionController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Your Position',
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
    String _formatTimestamp(String? iso) {
      if (iso == null || iso.isEmpty) return '';
      try {
        final dt = DateTime.parse(iso);
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final day = dt.day.toString().padLeft(2, '0');
        return '$month/$day/${dt.year} $hour:$minute $ampm';
      } catch (_) {
        return iso;
      }
    }
  final List<Map<String, String>> submittedData;
  final VoidCallback? onDownloadCsv;
  const HomePage({
    super.key,
    required this.submittedData,
    this.onDownloadCsv,
  });

  void _showDetailsDialog(BuildContext context, Map<String, String> row) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(row['name'] ?? 'Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(label: 'Position', value: row['position'] ?? ''),
                InfoRow(label: 'Timestamp', value: row['timestamp'] ?? ''),
                if ((row['signatureBase64'] ?? '').isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text('Signature:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Image.memory(
                        _decodeBase64(row['signatureBase64']!),
                        width: 200,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text('Image error'),
                      ),
                    ],
                  ),
                if ((row['signatureBase64'] ?? '').isNotEmpty)
                  InfoRow(label: 'Signature (Base64)', value: row['signatureBase64'] ?? '', maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Uint8List _decodeBase64(String b64) {
    try {
      return base64Decode(b64);
    } catch (_) {
      return Uint8List(0);
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white.withOpacity(0.95),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.dashboard_customize, color: Color(0xFF3CB6E3), size: 32),
                    const SizedBox(width: 14),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Welcome to the Dashboard!\nHere you can view, review, and download all submitted signatures.',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (submittedData.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: 80, color: Color(0xFF3CB6E3)),
                      SizedBox(height: 16),
                      Text(
                        'No signatures submitted yet.\nGo to Signature tab to create one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color(0xFF3CB6E3)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: submittedData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = submittedData[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF3CB6E3), width: 1),
                      ),
                      child: ListTile(
                        title: Text(
                          row['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        subtitle: Text(
                          'Position:  9${row['position'] ?? ''}\nTime: ${row['timestamp'] ?? ''}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.open_in_new, color: Color(0xFF3CB6E3)),
                        onTap: () => _showDetailsDialog(context, row),
                      ),
                    );
                  },
                ),
              ),
            if (submittedData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: onDownloadCsv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3CB6E3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download All Signatures as CSV'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Settings Page (coming soon)',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

