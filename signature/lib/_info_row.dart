import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  const InfoRow({required this.label, required this.value, this.maxLines = 1, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.work_outline, color: Colors.blue.shade400, size: 22),
              const SizedBox(width: 10),
              Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  value,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  onTap: () {},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $label!'),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: Colors.blue.shade200,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}