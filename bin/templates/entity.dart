import '../utils/custom_file.dart';

final entityFile = CustomFile(yaml: r''' 
entity: |
  abstract class $fileName|pascalcase { 
    
  }
''');
