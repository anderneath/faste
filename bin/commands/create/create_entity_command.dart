import 'dart:async';

import 'package:faste/app/template_info.dart';
import 'package:faste/faste.dart';
import '../../templates/entity.dart';
import '../../utils/inject_export.dart';
import '../../utils/template_file.dart';
import '../command_base.dart';

class CreateEntityCommand extends CommandBase {
  @override
  final name = 'entity';

  @override
  final description = 'Creates a Entity file';

  @override
  FutureOr run() async {
    final key = 'entity';
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
    final path = 'lib/$feature/domain/entities/${argResults?.rest.last}'
        .replaceFirst('_$key', '')
        .replaceFirst('.dart', '');
    final templateFile = await TemplateFile.getInstance(path, key);

    var result = await Faste.instance.template.createFile(
        info: TemplateInfo(
      yaml: entityFile,
      destiny: templateFile.file,
      key: key,
    ));
    await injectExport(templateFile.file.path, templateFile.file.parent);
    print(result);
    print('=======================================');
  }

  @override
  String? get invocationSuffix => null;
}

class CreateEntityAbbrCommand extends CreateEntityCommand {
  @override
  final name = 'e';
}
