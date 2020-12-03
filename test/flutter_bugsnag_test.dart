import 'package:flutter_bugsnag/flutter_bugsnag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

main() {
  group('BugsnagNotifier', () {
    BugsnagNotifier notifier;

    group('.addUser', () {
      setUp(() {
        notifier = BugsnagNotifier('TestKey');
      });

      test('should add a user to the notifier', () {
        notifier.addUser(
          userId: 'USR123',
          userName: 'John Doe',
          userEmail: 'john.doe@example.com',
        );

        expect(notifier.user, {
          'id': 'USR123',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
        });
      });
    });

    group('.notify', () {
      var mockHttp = MockClient();

      setUp(() {
        notifier = BugsnagNotifier('TestKey');
        notifier.client = mockHttp;
        notifier.innerPackageInfo = {
          'version': '1.1.0',
        };
        notifier.innerDeviceInfo = {
          'manufacturer': 'Xiaomi',
          'model': 'Note 7',
          'osName': 'Android',
          'osVersion': '12.0',
        };

        when(
          mockHttp.post(
            'https://notify.bugsnag.com/',
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => Future<http.Response>.value(
            http.Response('OK', 200),
          ),
        );
      });

      test('should send correct request header to bugsnag', () async {
        await notifier.notify(
          Exception('Test Error.'),
          StackTrace.current,
        );

        List<dynamic> capturedParams = verify(
          mockHttp.post(
            'https://notify.bugsnag.com/',
            headers: captureAnyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).captured;
        expect(
          capturedParams[0]['Content-Type'],
          'application/json',
        );
        expect(
          capturedParams[0]['Bugsnag-Api-Key'],
          'TestKey',
        );
      });

      test('should send correct file in stacktrace body to bugsnag', () async {
        await notifier.notify(
          Exception('Test Error.'),
          StackTrace.current,
        );

        List<dynamic> capturedParams = verify(
          mockHttp.post(
            'https://notify.bugsnag.com/',
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;
        expect(
          capturedParams[0],
          contains('flutter_bugsnag/test/flutter_bugsnag_test.dart'),
        );
      });
    });
  });
}
