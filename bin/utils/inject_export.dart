import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

import 'package:faste/app/line_params.dart';
import 'package:faste/faste.dart';

Future<void> injectExport(String path, Directory directory) async {
  final exportPath = '${directory.path}/${basename(directory.path)}.dart';
  if (basename(directory.parent.path) != 'domain' &&
      basename(directory.parent.path) != 'data' &&
      basename(directory.parent.path) != 'main' &&
      basename(directory.parent.path) != 'presentation' &&
      basename(directory.parent.path) != 'ui') {
    await injectExport(exportPath, directory.parent);
  }
  final injection = 'export \'${relative(path, from: directory.path)}\';';
  final exportFile = File(exportPath);
  var position = 0;
  if (await exportFile.exists()) {
    final streamLines = exportFile
        .openRead()
        .transform<String>(utf8.decoder)
        .transform<String>(LineSplitter());

    try {
      final lines = await streamLines.toList();
      final alreadyInFile = lines.any((line) => line.contains(injection));
      if (alreadyInFile) {
        return;
      }
      lines.add(injection);
      lines.sort();
      position = lines.indexWhere((line) => line == injection);
    } catch (e) {
      print('Error: $e');
    }
  } else {
    await exportFile.create();
  }
  var result = await Faste.instance.template.addLine(
    params: LineParams(
      exportFile,
      position: position,
      inserts: [injection],
    ),
  );

  print(result);
}
