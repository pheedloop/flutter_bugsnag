# flutter_bugsnag

flutter_bugsnag is a library that helps to notify a Bugsnag project of a runtime application error. It is not platform-specific meaning the notifier will work on iOS, Android, or the web.

## Getting Started

To notify bugsnag of all uncaught errors in the application:

- At the root of the application, import the library using `import 'package:flutter_bugsnag/flutter_bugsnag.dart';`
- Hook up an anonymous function to `FlutterError.onError`.
- In the anonymous function, initialize `BugsnagNotifier` by passing it the bugsnag project API key.
- Pass the `FlutterErrorDetails` (usually the first parameter of the anonymous function) exception and stack to the initialized notifier `notify` method.

```dart
main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    BugsnagNotifier bugsnagNotifier = BugsnagNotifier('the_bugsnag_project_api_key');
    bugsnagNotifier.notify(details.exception, details.stack);
  };

  runApp(
    ...
  );
}
```

### None Error Notification

It is possible to notify bugsnag of other less severer issues py passing a named argument to `.notify`

```dart
try {
  /// Erroring code
} catch (error, stackTrace) {
  bugsnagNotifier.notify(
    details.exception,
    details.stack,
    severity: ErrorSeverity.warning,
  );
}
```

### Adding User Info to Error

To notify bugsnag of the user that experienced the issue, call `.addUser` on the notifier instance.

```dart
notifier.addUser(
  userId: 'USR123',
  userName: 'John Doe',
  userEmail: 'john.doe@example.com',
);
```

### Gotcha

There is a [reported issue](https://github.com/flutter/flutter/issues/48972) were `FlutterError.onError` is not called on some uncaught error cases. Some solutions have been suggested in the thread.
