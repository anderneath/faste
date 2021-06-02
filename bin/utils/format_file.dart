import 'dart:io';

Future<void> formatFile(File file) async {
  await Process.run(
    'flutter',
    ['format', file.absolute.path],
    runInShell: true,
  );
}
