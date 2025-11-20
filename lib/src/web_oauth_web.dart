// Web implementation: uses dart:html to open OAuth URLs and read meta tags
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

String? getMetaContent(String name) {
  final el = html.document.querySelector('meta[name="$name"]');
  if (el == null) return null;
  return (el as html.MetaElement).content;
}

void openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
}
