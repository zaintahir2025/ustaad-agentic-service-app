// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  for (final dir in ['lib', 'test']) {
    for (final entity in Directory(dir).listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final text = entity.readAsStringSync().replaceAll('\r\n', '\n');
        entity.writeAsStringSync(text);
      }
    }
  }
  print('Line endings normalized to LF.');
}
