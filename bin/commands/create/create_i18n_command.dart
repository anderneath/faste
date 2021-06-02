import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:faste/app/template_info.dart';
import 'package:faste/faste.dart';
import 'package:recase/recase.dart';
import '../../templates/strings.dart';
import '../../utils/format_file.dart';
import '../../utils/inject_export.dart';
import '../../utils/template_file.dart';
import '../command_base.dart';

class CreateI18nCommand extends CommandBase {
  @override
  final name = 'i18n';

  @override
  final description = 'Creates i18n files';

  CreateI18nCommand() {
    argParser.addOption(
      'locale',
      abbr: 'l',
      defaultsTo: 'en_US',
      help: 'The locale to be included in supported locales',
      valueHelp: 'pt_BR',
    );
    argParser.addFlag(
      'update',
      abbr: 'u',
      negatable: false,
      help: 'Update i18n files with missing strings',
    );
    argParser.addFlag(
      'assets',
      abbr: 'a',
      negatable: false,
      help: 'Include assets i18n files in the creation',
    );
  }

  @override
  FutureOr run() async {
    final locale = argResults!['locale'] as String;
    final path = 'lib/app/presentation/i18n';
    final stringsFile = File('$path/strings.dart');
    if (!(await stringsFile.exists())) {
      final templateFile = await TemplateFile.getInstance(
        stringsFile.path.replaceFirst('.dart', ''),
      );
      await Faste.instance.template.createFile(
        info: TemplateInfo(
          yaml: stringsTemplateFile,
          destiny: templateFile.file,
          key: 'strings',
        ),
      );
      await injectExport(stringsFile.path, stringsFile.parent);
    }

    final lines = await stringsFile
        .openRead()
        .transform<String>(utf8.decoder)
        .transform<String>(LineSplitter())
        .toList();

    final firstOuterIndex = lines.indexWhere((line) => line.contains('{'));
    final lastOuterIndex = lines.lastIndexWhere((line) => line.contains('}'));
    final grossParams =
        lines.getRange(firstOuterIndex + 1, lastOuterIndex).toList();
    grossParams.removeWhere((param) {
      return param.trim().isEmpty ||
          param.contains(RegExp(r'(\/\/|\/\*|\*\/)'));
    });
    for (var i = grossParams.length; i > 0; i--) {
      if (!grossParams[i - 1].contains(';')) {
        grossParams[i - 1] += '\n${grossParams.removeAt(i)}';
      }
    }
    if (argResults!['update']) {
      final stringsCall = grossParams.map((param) {
        final split = param.trimLeft().split(' ');
        if (split[1] == 'get') {
          return split[2].replaceFirst(';', '');
        } else {
          return split[1].substring(0, split[1].indexOf('('));
        }
      }).toList();
      final stringsDir = Directory('$path/translations/strings');
      final stringsFiles = await stringsDir
          .list()
          .where((file) => !file.path.endsWith('strings.dart'))
          .toList();
      for (final strings in stringsFiles) {
        final lines = await (strings as File)
            .openRead()
            .transform<String>(utf8.decoder)
            .transform<String>(LineSplitter())
            .toList();
        var linesLength = lines.length;
        final firstOuterIndex = lines.indexWhere((line) => line.contains('{'));
        final lastOuterIndex =
            lines.lastIndexWhere((line) => line.contains('}'));
        final grossParams =
            lines.getRange(firstOuterIndex + 1, lastOuterIndex).toList();
        grossParams.removeWhere((param) {
          return param.trim().isEmpty ||
              param.contains(RegExp(r'(\/\/|\/\*|\*\/|@)'));
        });
        // TODO stopped here
        final params = grossParams.map((param) {
          param = param.replaceFirst(';', '');
          if (param.contains(' get ')) {
            return '  @override\n$param => null;';
          } else {
            return '  @override\n$param {\n    return null;\n  }';
          }
        }).toList();
        for (var i = 0; i < stringsCall.length; i++) {
          params.firstWhere(
            (param) => param.contains(stringsCall[i]),
            orElse: () {
              return params[i];
            },
          );
        }
      }
    }
    final params = grossParams.map((param) {
      param = param.replaceFirst(';', '');
      if (param.contains(' get ')) {
        return '  @override\n$param => null;';
      } else {
        return '  @override\n$param {\n    return null;\n  }';
      }
    }).join('\n\n');

    var templateFile = await TemplateFile.getInstance(
      '$path/translations/strings/strings_${locale.toLowerCase().snakeCase}',
    );
    var result = await Faste.instance.template.createFile(
      info: TemplateInfo(
        yaml: stringsTemplateFile,
        destiny: templateFile.file,
        key: 'strings_locale',
        args: [params],
      ),
    );
    await injectExport(templateFile.file.path, templateFile.file.parent);
    await injectExport(
      '${templateFile.file.parent.path}/strings.dart',
      templateFile.file.parent.parent,
    );
    print(result);
    if (argResults!['assets'] as bool) {
      templateFile = await TemplateFile.getInstance(
        '$path/translations/assets/assets_${locale.toLowerCase().snakeCase}',
      );
      result = await Faste.instance.template.createFile(
        info: TemplateInfo(
          yaml: stringsTemplateFile,
          destiny: templateFile.file,
          key: 'assets_locale',
          args: [''],
        ),
      );
      await injectExport(templateFile.file.path, templateFile.file.parent);
      await injectExport(
        '${templateFile.file.parent.path}/assets.dart',
        templateFile.file.parent.parent,
      );
    }
    await formatFile(templateFile.file);
    print(result);
    print('=======================================');
    return;
  }

  @override
  String? get invocationSuffix => null;
}

class CreateI18nAbbrCommand extends CreateI18nCommand {
  @override
  final name = 'i';
}
