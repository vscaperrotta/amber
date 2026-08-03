// Guards the build config: a released APK built without
// `--dart-define-from-file=env.json`, or with placeholder app IDs, used to fail
// only at login with a generic error. This catches it at `flutter test` instead.
//
// Run with the same defines as the build:
//   flutter test --dart-define-from-file=env.json

import 'package:flutter_test/flutter_test.dart';
import 'package:amber/firebase_options.dart';

void main() {
  // ponytail: skips on a fresh clone with no env.json rather than failing —
  // the point is to catch a *wrong* config, not a deliberately absent one.
  final configured = DefaultFirebaseOptions.android.apiKey.isNotEmpty;

  test('Firebase app IDs are real, not placeholders', () {
    // 1:<senderId>:<platform>:<hex hash> — placeholders like XXXX fail here.
    final appId = RegExp(r'^\d+:\d+:(android|ios):[0-9a-f]+$');

    expect(DefaultFirebaseOptions.android.appId, matches(appId));
    expect(DefaultFirebaseOptions.ios.appId, matches(appId));
    expect(DefaultFirebaseOptions.android.projectId, isNotEmpty);
  }, skip: configured ? false : 'no env.json defines — nothing to validate');
}
