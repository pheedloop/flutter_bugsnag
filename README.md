# flutter_bugsnag

flutter_bugsnag is a library that helps to notify your Bugsnag project of an error in your application. It is not platform-specific meaning with just this notifier will work on iOS, Android, or the web.

## Getting Started

To notify bugsnag of all uncaught errors in the application:

- At the root of your application, import the library using `import 'package:flutter_bugsnag/flutter_bugsnag.dart';`
- Initialize `BugsnagNotifier` by passing it your bugsnag project api key.
- Hook up an anonymous function `FlutterError.onError` where you pass the `FlutterErrorDetails` exception and stack to the initialized notifier `notify` method.

```dart
main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    BugsnagNotifier bugsnagNotifier = BugsnagNotifier('your_bugsnag_project_api_key');
    bugsnagNotifier.notify(details.exception, details.stack);
  };

  runApp(
    ...
  );
}
```
