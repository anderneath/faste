import '../utils/custom_file.dart';

final _domainUsecaseTemplate = r''' 
domain_usecase: |
  abstract class $fileName|pascalcase { 
    Future<$arg1> $arg2($arg3);
  }
''';

final domainUsecaseFile = CustomFile(yaml: _domainUsecaseTemplate);

final _localUsecaseTemplate = r''' 
data_local_usecase: |
  $arg1

  class $fileName|pascalcase implements $arg2 {
    final LocalStorage localStorage;

    $fileName|pascalcase({@required this.localStorage});

    Future<$arg3> $arg4($arg5) async {
      try {
        $arg6
      } on Exception {
        throw DomainError.unexpected;
      }
    }
  }
''';

final localUsecaseFile = CustomFile(yaml: _localUsecaseTemplate);

final _remoteUsecaseTemplate = r''' 
data_remote_usecase: |
  $arg1

  class $fileName|pascalcase implements $arg2 {
    final RefreshToken refreshToken;
    final HttpClient httpClient;
    final LoadUser loadUser;
    final String url;

    $fileName|pascalcase({
      required this.refreshToken,
      required this.httpClient,
      required this.loadUser,
      required this.url,
    });

    Future<$arg3> $arg4($arg5{
    bool updateTokenIfNecessary = true,
  }) async {
      UserEntity user;
      try {
        user = await loadUser.load();
        $arg6
        final response = await httpClient.request(
          HttpMethod.$arg7,
          url: url,
          authorization: user?.accessToken,
          body: params.toJson(),
        );
        if (response.values.isEmpty) {
          throw InvalidDataError();
        }$arg8
      } on UnauthorizedError {
        if (user != null && updateTokenIfNecessary) {
          await refreshToken.refresh(user);
          return await $arg4($arg5updateTokenIfNecessary: false);
        } else {
          throw DomainError.unauthenticated;
        }
      } on HttpError {
        throw DomainError.unexpected;
      }
    }
  }
''';

final remoteUsecaseFile = CustomFile(yaml: _remoteUsecaseTemplate);
