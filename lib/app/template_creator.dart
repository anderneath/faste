import 'package:faste/app/line_params.dart';
import 'package:faste/app/yaml_service.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

import 'template_info.dart';

class TemplateCreator {
  Future<String> createFile({required TemplateInfo info}) async {
    final fileName =
        info.destiny.uri.pathSegments.last.replaceFirst('.dart', '');
    if (await info.destiny.exists()) {
      return 'File $fileName already exists';
    }

    await info.destiny.create(recursive: true);
    final service = YamlService(yaml: info.yaml);
    final node = service.getValue([info.key]);
    if (node is YamlScalar) {
      var list = node.value.toString().trim().split('/n');
      list = list
          .map<String>((e) => _processLine(e, info.args, fileName))
          .toList();
      await info.destiny.writeAsString(list.join('\n'));
      return 'File $fileName was created';
    } else {
      return 'Incorrect YAML template';
    }
  }

  Future<String> addLine({required LineParams params}) async {
    var lines = await params.file.readAsLines();
    lines = params.replaceLine == null
        ? lines
        : lines.map<String>(params.replaceLine!).toList();
    lines.insertAll(params.position, params.inserts);
    await params.file.writeAsString(lines.join('\n'));

    if (params.inserts.isEmpty) {
      return '${params.file.uri.pathSegments.last} added line';
    }
    return '${params.file.uri.pathSegments.last} added line ${params.inserts.first}';
  }

  String _processLine(String value, List<String> args, String fileName) {
    value =
        value.replaceAll('\$fileName|camelcase', ReCase(fileName).camelCase);
    value =
        value.replaceAll('\$fileName|pascalcase', ReCase(fileName).pascalCase);
    value = value.replaceAll('\$fileName', fileName);

    if (args.isEmpty) return value;
    for (var i = 0; i < args.length; i++) {
      final key = '\$arg${i + 1}';
      value = value.replaceAll(key, args[i]);
    }
    return value;
  }
}
