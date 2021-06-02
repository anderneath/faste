import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

import 'package:faste/app/template_info.dart';
import 'package:faste/faste.dart';
import 'package:recase/recase.dart';
import '../../constants.dart';
import '../../templates/model.dart';
import '../../utils/format_file.dart';
import '../../utils/inject_export.dart';
import '../../utils/template_file.dart';
import '../command_base.dart';

class CreateModelCommand extends CommandBase {
  @override
  final name = 'model';

  @override
  final description = 'Creates a Model file';

  @override
  FutureOr run() async {
    final key = 'model';
    var feature = 'app';
    final args = argResults?.rest ?? [];
    if (args.length == 2) {
      feature = args.first;
    } else if (args.length > 2) {
      print(
          'More than 2 arguments are not allowed:\n - First must be the feature\n - Second must be the $key');
      print('=======================================');
      return;
    }
    final pathEnd = '${argResults?.rest.last}'
        .replaceFirst('_$key', '')
        .replaceFirst('.dart', '');
    var filename = basename(ReCase(pathEnd).snakeCase);
    final lastIndex = filename.indexOf('_');
    filename =
        filename.substring(0, lastIndex == -1 ? filename.length : lastIndex);
    final path = 'lib/$feature/data/models/$pathEnd';
    final entityFile =
        File('lib/$feature/domain/entities/${pathEnd}_entity.dart');
    if (!await entityFile.exists()) {
      print(
          'File ${filename}_entity must be created before the model\nPlease run: faste g e ${feature != 'app' ? '$feature ' : ''}$pathEnd\nTo generate the Entity first');
      print('=======================================');
      return;
    }

    final lines = await entityFile
        .openRead()
        .transform<String>(utf8.decoder)
        .transform<String>(LineSplitter())
        .toList();

    // TODO validate if variables are placed before constructor
    final firstOuterIndex =
        lines.indexWhere((line) => line.contains('Entity {'));
    final lastOuterIndex = lines.indexWhere((line) => line.contains('Entity('));
    print(lastOuterIndex);
    if (lastOuterIndex == -1) {
      print(
          'File ${filename}_entity must have at least one variable\nand a constructor initializing it\'s variables.');
      print('=======================================');
      return;
    }
    final grossParams =
        lines.getRange(firstOuterIndex + 1, lastOuterIndex).toList();
    grossParams.removeWhere((param) => param.trim().isEmpty);
    final params = grossParams
        .map((param) => param
            .replaceFirst('final ', '')
            .replaceFirst(';', '')
            .trim()
            .split(' ')[1]
            .trim())
        .toList();
    var initParams = grossParams
        .map((param) =>
            '${param.contains('?') || param.contains('=') ? '' : '${nullSafety ? '' : '@'}required '}${param.replaceFirst('final ', '').replaceFirst(';', '').trim()}')
        .join(', ');
    final filenameLength = filename.length;
    final initLength = filenameLength + initParams.length + 11;
    if (initLength > rowCharactersLimit) {
      initParams += ',';
    }
    var parentParams = params.map((param) => param).join(', ');
    if (initParams.endsWith(',')) {
      if (parentParams.length + 9 > 80) {
        parentParams += ',';
      }
    } else {
      if (initLength + parentParams.length + 11 > 80) {
        parentParams += ',';
      }
    }
    var fromJsonParams = params
        .map((param) => '$param: json[\'${ReCase(param).snakeCase}\'],')
        .join('\n      ');
    var fromEntityParams =
        params.map((param) => '$param: entity.$param,').join('\n      ');
    var toJsonParams = params
        .map((param) => '\'${ReCase(param).snakeCase}\': $param,')
        .join('\n      ');
    final templateFile = await TemplateFile.getInstance(path, key);

    var result = await Faste.instance.template.createFile(
      info: TemplateInfo(
        yaml: modelFile,
        destiny: templateFile.file,
        key: key,
        args: [
          ReCase(basenameWithoutExtension('${filename}_entity')).pascalCase,
          initParams,
          parentParams,
          fromJsonParams,
          fromEntityParams,
          toJsonParams,
          initParams.contains('@')
              ? '\nimport \'package:meta/meta.dart\';\n'
              : ''
        ],
      ),
    );
    await injectExport(templateFile.file.path, templateFile.file.parent);
    await formatFile(templateFile.file);
    print(result);
    print('=======================================');
  }

  @override
  String? get invocationSuffix => null;
}

class CreateModelAbbrCommand extends CreateModelCommand {
  @override
  final name = 'm';
}
