import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  group('SolvedApiV3Contract', () {
    test('describes the verified user request for direct and proxy targets',
        () {
      final endpoint = const SolvedApiV3Contract().userShow('index');

      expect(endpoint.direct.baseUri, Uri.parse('https://solved.ac/api/v3/'));
      expect(endpoint.direct.path, 'user/show');
      expect(endpoint.direct.queryParameters, {'handle': 'index'});
      expect(
        endpoint.proxy.baseUri,
        Uri.parse('https://codepoker.w8385.dev/solved/'),
      );
      expect(endpoint.proxy.path, 'user/show');
      expect(endpoint.proxy.queryParameters, {'handle': 'index'});
    });
  });

  group('SolvedApiTarget', () {
    test('normalizes its base and defensively copies query parameters', () {
      final query = {'handle': 'index'};
      final target = SolvedApiTarget(
        baseUri: Uri.parse('https://example.com/api'),
        path: 'user/show',
        queryParameters: query,
      );
      query['handle'] = 'changed';

      expect(target.baseUri, Uri.parse('https://example.com/api/'));
      expect(target.queryParameters, {'handle': 'index'});
      expect(
        () => target.queryParameters['handle'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects ambiguous bases and non-relative endpoint paths', () {
      expect(
        () => SolvedApiTarget(
          baseUri: Uri.parse('/api/v3/'),
          path: 'user/show',
        ),
        throwsArgumentError,
      );
      expect(
        () => SolvedApiTarget(
          baseUri: Uri.parse('https://example.com/api/?token=secret'),
          path: 'user/show',
        ),
        throwsArgumentError,
      );
      for (final path in [
        '/user/show',
        '../user/show',
        '%2e%2e/user/show',
        r'user\show',
        'https://evil.example/user/show',
        'user/show?handle=index',
        'user/show#fragment',
      ]) {
        expect(
          () => SolvedApiTarget(
            baseUri: Uri.parse('https://example.com/api/'),
            path: path,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
