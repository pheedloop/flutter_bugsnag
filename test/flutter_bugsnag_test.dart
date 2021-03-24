import 'package:flutter_bugsnag/flutter_bugsnag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

main() {
  group('BugsnagNotifier', () {
    late BugsnagNotifier notifier;

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
  });
}
