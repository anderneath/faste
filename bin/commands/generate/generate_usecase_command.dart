import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

import 'package:faste/app/template_info.dart';
import 'package:faste/faste.dart';
import 'package:recase/recase.dart';
import '../../constants.dart';
import '../../templates/model.dart';
import '../../templates/usecase.dart';
import '../../utils/format_file.dart';
import '../../utils/inject_export.dart';
import '../../utils/template_file.dart';
import '../command_base.dart';

class GenerateUsecaseCommand extends CommandBase {
  @override
  final name = 'usecase';

  @override
  final description = 'Creates use case files';

  GenerateUsecaseCommand() {
    argParser.addFlag('notest',
        abbr: 'n', negatable: false, help: 'Don`t create file test');
    argParser.addOption('connection',
        abbr: 'c',
        allowed: [
          'local',
          'remote',
        ],
        defaultsTo: 'remote',
        allowedHelp: {
          'local': 'Creates a local use case',
          'remote': 'Creates a remote use case',
        },
        help: 'Define use case\'s connection type');
    argParser.addOption('operation',
        abbr: 'o',
        allowed: ['load', 'save', 'edit', 'delete'],
        allowedHelp: {
          'load': 'Creates a use case to load/read something',
          'save': 'Creates a use case to save/add something',
          'edit': 'Creates a use case to edit/update something',
          'delete': 'Creates a use case to delete something',
        },
        help: 'Define use case\'s operation');
  }

  @override
  FutureOr run() async {
    final key = 'usecase';
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
    if (argResults!['operation'] == null) {
      print('Define the operation of the use case with --operation or -o');
      print('=======================================');
      return;
    }
    final operation = argResults!['operation'] as String;
    final pathEnd = '${argResults?.rest.last}'
        .replaceFirst('_$key', '')
        .replaceFirst('.dart', '');
    var filename = basename(pathEnd).snakeCase;
    final lastIndex = filename.indexOf('.');
    filename =
        filename.substring(0, lastIndex == -1 ? filename.length : lastIndex);
    final path = '$feature/data/usecases/$pathEnd';
    final domainFile = File('lib/$feature/domain/usecases/$pathEnd.dart');
    File? entityFile;
    await for (final feature in Directory('lib').list()) {
      if (feature is Directory) {
        final entities = Directory('${feature.path}/domain/entities/');
        if (await entities.exists()) {
          await for (final entity in entities.list()) {
            final splitted = filename
                .replaceFirst('_entity', '')
                .replaceFirst('.dart', '')
                .split('_');
            splitted.removeAt(0);
            final entityClass = splitted.join('_');
            if (basename(entity.path).contains(entityClass)) {
              entityFile = entity as File;
              break;
            }
          }
          if (entityFile != null) {
            break;
          }
        }
      }
    }
    final entityClass = basename(entityFile?.path ?? 'String').pascalCase;
    final entityName = entityClass.camelCase.replaceFirst('Entity', '');
    if (!await domainFile.exists()) {
      final templateFile = await TemplateFile.getInstance(
          domainFile.path.replaceFirst('lib/', '').replaceFirst('.dart', ''),
          null);
      final isList = filename.endsWith('s');
      var entityParams = [];
      if (entityFile != null) {
        /////////////////////////////////////// start duplicated code
        final lines = await entityFile
            .openRead()
            .transform<String>(utf8.decoder)
            .transform<String>(LineSplitter())
            .toList();

        // TODO validate if variables are placed before constructor
        final firstOuterIndex =
            lines.indexWhere((line) => line.contains('Entity {'));
        final lastOuterIndex =
            lines.indexWhere((line) => line.contains('Entity('));
        if (lastOuterIndex == -1) {
          print(
              'File ${filename}_entity must have at least one variable\nand a constructor initializing it\'s variables.');
          print('=======================================');
          return;
        }
        final grossParams =
            lines.getRange(firstOuterIndex + 1, lastOuterIndex).toList();
        grossParams.removeWhere((param) => param.trim().isEmpty);
        entityParams = grossParams
            .map((param) =>
                param.replaceFirst('final ', '').replaceFirst(';', '').trim())
            .toList();
        /////////////////////////////////////// end duplicated code
      }
      var response = 'void';
      var params = '';
      switch (operation) {
        case 'load':
          response = isList ? 'List<$entityClass>' : entityClass;
          params = isList ? '' : 'String ${entityName}Uuid';
          break;
        case 'save':
          params = isList
              ? '${filename.pascalCase}Params params'
              : entityParams.where((param) {
                  return !param.contains(' uuid') && !param.contains(' id');
                }).join(', ');

          break;
        case 'edit':
          params = isList
              ? '${filename.pascalCase}Params params'
              : entityParams.join(', ');
          break;
        case 'delete':
          params = isList
              ? 'List<String> ${entityName}Uuids'
              : 'String ${entityName}Uuid';
          break;
        default:
      }
      if (params.isNotEmpty &&
          response.length + operation.length + params.length + 16 > 80) {
        params += ',';
      }
      await Faste.instance.template.createFile(
        info: TemplateInfo(
          yaml: domainUsecaseFile,
          destiny: templateFile.file,
          key: 'domain_usecase',
          args: [response, operation, params],
        ),
      );
      await formatFile(templateFile.file);
      print(
          'File $filename at domain layer was created!\nAfter defining the params and return, please run again: faste g u ${argResults!['connection'] == 'local' ? '-c local' : ''} -o ${argResults!['operation']} ${feature != 'app' ? '$feature ' : ''}$pathEnd\nTo generate the use case also at data layer.');
      print('=======================================');
      return;
    }
    return;

    final lines = await domainFile
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

class GenerateUsecaseAbbrCommand extends GenerateUsecaseCommand {
  @override
  final name = 'u';
}
