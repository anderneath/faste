import '../utils/custom_file.dart';

final _entityTemplate = r''' 
entity: |
  abstract class $fileName|pascalcase { 
    
  }
''';

final entityFile = CustomFile(yaml: _entityTemplate);
