import '../command_base.dart';
import '../commands.dart';
import 'generate_usecase_command.dart';

class GenerateCommand extends CommandBase {
  @override
  final name = 'generate';
  @override
  final description =
      'Creates a module, page, widget or repository according to the option.';

  GenerateCommand() {
    // addSubcommand(GenerateFeatureCommand());
    // addSubcommand(GeneratePageCommand());
    // addSubcommand(GeneratePresenterCommand());
    // addSubcommand(GenerateViewModelCommand());
    // addSubcommand(GenerateComponentCommand());
    // addSubcommand(GenerateStringCommand());
    // addSubcommand(GenerateAssetCommand());
    addSubcommand(GenerateUsecaseCommand());
    addSubcommand(GenerateUsecaseAbbrCommand());
    addSubcommand(GenerateModelCommand());
    addSubcommand(GenerateModelAbbrCommand());
    addSubcommand(GenerateEntityCommand());
    addSubcommand(GenerateEntityAbbrCommand());
  }

  @override
  String? get invocationSuffix => null;
}

class GenerateCommandAbbr extends GenerateCommand {
  @override
  final name = 'g';
}
