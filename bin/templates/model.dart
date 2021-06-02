import '../utils/custom_file.dart';

final _modelTemplate = r''' 
model: |
  import 'dart:convert';
  $arg7
  import '../../domain/entities/entities.dart';

  class $fileName|pascalcase extends $arg1 { 
    $fileName|pascalcase({$arg2}) : super($arg3);

    factory $fileName|pascalcase.fromJson(Map<String, dynamic> json) {
      return $fileName|pascalcase($arg4);
    }

    factory $fileName|pascalcase.fromEntity($fileName|pascalcase entity) {
      return $fileName|pascalcase($arg5);
    }

    Map<String, dynamic> toJson() {
      return {$arg6};
    }

    @override
    String toString() => json.encode(toJson());
  }
''';

final modelFile = CustomFile(yaml: _modelTemplate);
