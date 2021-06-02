import '../command_base.dart';
import '../commands.dart';
import 'create_usecase_command.dart';

class CreateCommand extends CommandBase {
  @override
  final name = 'create';
  @override
  final description =
      'Creates a module, page, widget or repository according to the option.';

  CreateCommand() {
    // addSubcommand(GenerateFeatureCommand());
    // addSubcommand(GeneratePageCommand());
    // addSubcommand(GeneratePresenterCommand());
    // addSubcommand(GenerateViewModelCommand());
    // addSubcommand(GenerateComponentCommand());
    // addSubcommand(GenerateAssetCommand());
    addSubcommand(CreateI18nCommand());
    addSubcommand(CreateI18nAbbrCommand());
    addSubcommand(CreateUsecaseCommand());
    addSubcommand(CreateUsecaseAbbrCommand());
    addSubcommand(CreateModelCommand());
    addSubcommand(CreateModelAbbrCommand());
    addSubcommand(CreateEntityCommand());
    addSubcommand(CreateEntityAbbrCommand());
  }

  @override
  String? get invocationSuffix => null;
}

class CreateCommandAbbr extends CreateCommand {
  @override
  final name = 'c';
}
