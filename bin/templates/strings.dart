import '../utils/custom_file.dart';

final stringsTemplateFile = CustomFile(yaml: r''' 
strings: |
  abstract class Strings { 
    
  }
strings_locale: |
  import '../../strings.dart';

  class $fileName|pascalcase implements Strings { 
  $arg1
  }
assets_locale: |
  import '../../../assets/assets.dart';

  class $fileName|pascalcase extends Assets { 
  $arg1
  }
''');
