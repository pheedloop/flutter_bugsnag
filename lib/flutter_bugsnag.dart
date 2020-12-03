library flutter_bugsnag;

import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';

String notifierName = 'Flutter Bugsnag';
String notifierVersion = '0.0.1';
String notifierUrl = 'https://github.com/pheedloop/flutter_bugsnag';

enum ErrorSeverity {
  error,
  warning,
  info,
}

class BugsnagNotifier {
  final String _apiKey;
  String _releaseStage;
  Map<String, String> _user;
  @visibleForTesting
  Map<String, String> innerPackageInfo;
  @visibleForTesting
  Map<String, String> innerDeviceInfo;
  @visibleForTesting
  var client = http.Client();

  /// Get the current user infomation
  Map<String, String> get user {
    return this._user;
  }

  /// Get the package information of the current device
  Future<Map<String, String>> get _packageInfo async {
    if (this.innerPackageInfo != null) {
      return this.innerPackageInfo;
    }

    if (kIsWeb) {
      this.innerPackageInfo = {
        'version': 'web-version',
      };
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      this.innerPackageInfo = {
        'version': packageInfo.version,
      };
    }
    return this.innerPackageInfo;
  }

  /// Get the manufactuer, model, osName and osVersion of the device
  Future<Map<String, String>> get _deviceInfo async {
    if (this.innerDeviceInfo != null) {
      return this.innerDeviceInfo;
    }

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        AndroidDeviceInfo android = await DeviceInfoPlugin().androidInfo;
        this.innerDeviceInfo = {
          'manufacturer': android.manufacturer,
          'model': android.model,
          'osName': 'Android',
          'osVersion': android.version.release,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo ios = await DeviceInfoPlugin().iosInfo;
        this.innerDeviceInfo = {
          'manufacturer': 'Apple',
          'model': ios.model,
          'osName': 'iOS',
          'osVersion': ios.systemVersion,
        };
      }
    }

    return this.innerDeviceInfo;
  }

  /// Creates a new bugsnag reporter with your Bugsnag API key and [releaseState]
  /// which defults to production.
  ///
  /// ```dart
  /// new BugsnagNotifier('YOUR_BUGSNAG_API_KEY')
  /// ```
  BugsnagNotifier(this._apiKey, {String releaseStage = 'production'}) {
    this._releaseStage = releaseStage;
  }

  /// Adds [userId], [userName] and [userEmail] to bugsnag error reporter
  ///
  /// ```dart
  /// addUser(userId: 'USR123', userName: 'John Doe', userEmail: 'john.doe@example.com')
  /// ```
  void addUser({
    @required String userId,
    @required String userName,
    @required String userEmail,
  }) {
    this._user = {
      'id': userId,
      'name': userName,
      'email': userEmail,
    };
  }

  /// Send [error] and [stackTrace] to bugsnag
  ///
  /// ```dart
  /// try {
  ///   throw Exception('Application error.');
  /// } catch (error, stackTrace) {
  ///   bugsnagNotifierInstance.notify(error, stackTrace)
  /// }
  /// ```
  Future<void> notify(
    Exception error,
    StackTrace stackTrace, {
    ErrorSeverity severity = ErrorSeverity.error,
  }) async {
    Map<String, dynamic> exception = {
      'errorClass': error.runtimeType.toString(),
      'message': error.toString(),
      'stacktrace': this._parseStackTrace(stackTrace),
    };

    await this._sendError([exception], severity);
  }

  /// Convert stacktrace to list of bugsnag stacktrace objects
  List<Map<String, String>> _parseStackTrace(StackTrace stackTrace) {
    List<Map<String, String>> stackTraceObjects = <Map<String, String>>[];

    LineSplitter ls = LineSplitter();
    List<String> stackTraceLines = ls.convert(stackTrace.toString());

    for (var line in stackTraceLines) {
      // if (line.contains('<asynchronous suspension>') == false) {
      List<String> splitStackTraceLine = line.split(
        RegExp(r'(?!(?<=\w)\s(?=\w))([\s:)(]+)'),
      );

      stackTraceObjects.add({
        'file': splitStackTraceLine.length >= 4
            ? splitStackTraceLine[3].toString()
            : '',
        'lineNumber': splitStackTraceLine.length >= 5
            ? splitStackTraceLine[4].toString()
            : '',
        'columnNumber': splitStackTraceLine.length >= 6
            ? splitStackTraceLine[5].toString()
            : '',
        'method': splitStackTraceLine.length >= 2
            ? splitStackTraceLine[1].toString()
            : splitStackTraceLine[0].toString(),
      });
      // }
    }

    return stackTraceObjects;
  }

  /// Notify bugsnag of the [errors]
  Future<void> _sendError(
    List<Map<String, dynamic>> errors,
    ErrorSeverity severity,
  ) async {
    try {
      Map<String, String> packageInfo = await this._packageInfo;
      Map<String, String> deviceInfo = await this._deviceInfo;

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Bugsnag-Api-Key': this._apiKey,
        'Bugsnag-Payload-Version': '5',
        'Bugsnag-Sent-At': DateTime.now().toUtc().toIso8601String(),
      };

      Map<String, dynamic> requestBody = {
        'apiKey': this._apiKey,
        'payloadVersion': '5',
        'notifier': {
          'name': notifierName,
          'version': notifierVersion,
          'url': notifierUrl,
        },
        'events': [
          {
            'app': {
              'version': packageInfo['version'],
              'releaseStage': this._releaseStage,
            },
            'device': deviceInfo,
            'exceptions': errors,
            'user': this._user,
            'severity': severity.toString(),
          }
        ]
      };

      print('Reporting to bugsnag...');
      var response = await client.post(
        'https://notify.bugsnag.com/',
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (!response.body.toLowerCase().contains('ok')) {
        throw Exception('Bugsnag did not accept error request format.');
      }
    } catch (error, stackTrace) {
      print(
          '-------------------------FLUTTER_BUGSNAG-------------------------');
      print(
          'Errored while reporting to bugsnag:\nReport the issue here: https://github.com/pheedloop/flutter_bugsnag/issues/new?labels=bug&template=bug.md\n\n');
      print(error);
      print(stackTrace);
      print(
          '-----------------------------------------------------------------');
    } finally {
      client.close();
    }
  }
}
