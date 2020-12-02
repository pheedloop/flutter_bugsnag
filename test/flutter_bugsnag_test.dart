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
      var http = MockClient();
      setUp(() {
        notifier = BugsnagNotifier('TestKey');
        notifier.client = http;
      });

      test('should send correct request header to bugsnag', () {
        when(
          http.post(
            'https://notify.bugsnag.com/',
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenReturn(null);

        notifier.notify(
          Exception('Test Error.'),
          StackTrace.current,
        );

        List<dynamic> capturedParams = verify(
          http.post(
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

      test('should send correct request body to bugsnag', () {
        when(
          http.post(
            'https://notify.bugsnag.com/',
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenReturn(null);

        notifier.notify(
          Exception('Test Error.'),
          StackTrace.current,
        );

        List<dynamic> capturedParams = verify(
          http.post(
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
