import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/core/constants/app_version.dart';

/// [AppVersion] duplicates what pubspec.yaml already says, because nothing in
/// Dart can read the manifest at runtime. This is the check that keeps the copy
/// honest — bump one and forget the other, and the suite says so.
void main() {
  test('AppVersion matches pubspec.yaml', () {
    final RegExpMatch? version = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());

    expect(
      version,
      isNotNull,
      reason: 'pubspec.yaml has no `version: x.y.z+n`',
    );
    expect(AppVersion.name, version!.group(1));
    expect(AppVersion.build, int.parse(version.group(2)!));
  });

  test('the label is what the screens print', () {
    expect(AppVersion.label, 'v1.0.0 build 1');
  });
}
