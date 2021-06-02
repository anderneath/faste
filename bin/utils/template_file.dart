import 'dart:io';

import 'package:recase/recase.dart';

class TemplateFile {
  late final File file;
  late final File fileTest;
  late final String fileName;
  late final fileNameWithUppeCase;

  TemplateFile._(String path, String type) {
    file = File('lib/$path$type.dart');
    fileTest = File('test/$path${type}_test.dart');
    fileName = ReCase(Uri.parse(path).pathSegments.last).camelCase;
    fileNameWithUppeCase = fileName[0].toUpperCase() + fileName.substring(1);
  }

  static Future<TemplateFile> getInstance(String path, String? key) async {
    return TemplateFile._(path, key == null ? '' : '_$key');
  }
}
