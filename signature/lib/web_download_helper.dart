// Only imported on web
// lib/web_download_helper.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(String content, String fileName) {
  final blob = html.Blob([content]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
