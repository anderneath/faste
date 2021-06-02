import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:faste/version.dart';
import 'package:io/io.dart';

import 'commands/commands.dart';

Future main(List<String> arguments) async {
  final runner = configureCommand(arguments);

  var hasCommand = runner.commands.keys.any((x) => arguments.contains(x));

  if (hasCommand) {
    try {
      await executeCommand(runner, arguments);
      exit(ExitCode.success.code);
    } on UsageException catch (error) {
      print(error);
      exit(ExitCode.ioError.code);
    }
  } else {
    var parser = ArgParser();
    parser = runner.argParser;
    var results = parser.parse(arguments);
    executeOptions(results, arguments, runner);
  }
}

void executeOptions(
    ArgResults results, List<String> arguments, CommandRunner runner) {
  if (results.wasParsed('help') || arguments.isEmpty) {
    print(runner.usage);
  } else if (results.wasParsed('version')) {
    version(packageVersion);
  } else {
    print('Command not found!\n');
    print(runner.usage);
  }
}

Future executeCommand(CommandRunner runner, List<String> arguments) {
  return runner.run(arguments);
}

CommandRunner configureCommand(List<String> arguments) {
  var runner =
      CommandRunner('faste', 'CLI package manager and template for Flutter.')
        ..addCommand(GenerateCommand())
        ..addCommand(GenerateCommandAbbr());

  runner.argParser.addFlag('version', abbr: 'v', negatable: false);
  return runner;
}

void version(String version) async {
  print('''FASTE''');
  print('CLI package manager and template for Flutter');
  print('');
  print('Faste version: $version');
}
