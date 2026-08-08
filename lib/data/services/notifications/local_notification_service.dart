import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/profile/profile_model.dart';

/// Device-side scheduling. No push service, no server: renewal dates are
/// deterministic and known the moment a subscription is created.
class LocalNotificationService {
  const LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'upcoming_payments';

  /// iOS refuses to keep more than 64 pending local notifications. The
  /// scheduler works a 30-day window and reschedules on every launch, so this
  /// is the ceiling it trims to.
  static const int maxPending = 60;

  /// Reminders fire mid-morning: a payment notice at 3am is a notification
  /// people turn off.
  static const int hourOfDay = 9;

  static bool _ready = false;
  static String _timezone = ProfileModel.defaultTimezone;

  static bool _zonesLoaded = false;

  /// Reminders fire on the wall clock the person actually lives on. Falls back
  /// to the default when the zone name is not one the tz database knows —
  /// including the case where the fallback itself is unavailable, because a
  /// throw here would stop scheduling for every subscription.
  static void configureTimezone(String name) {
    if (!_zonesLoaded) {
      tz_data.initializeTimeZones();
      _zonesLoaded = true;
    }
    for (final String candidate in [name, ProfileModel.defaultTimezone]) {
      try {
        tz.setLocalLocation(tz.getLocation(candidate));
        _timezone = candidate;
        return;
      } on Object {
        continue;
      }
    }
  }

  static String get timezone => _timezone;

  /// Returns false when the platform side is unavailable — most often a hot
  /// restart after the plugin was added, where the native registrant has not
  /// run. Reminders are optional, so this reports rather than throws.
  static Future<bool> initialize() async {
    if (_ready) {
      return true;
    }
    configureTimezone(_timezone);

    _ready = await _guard('initialize', () async {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Asked for explicitly below, so the first launch is not a
            // permission prompt before the user has seen anything.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    });
    return _ready;
  }

  /// Returns false when the user declined, or when the platform side is
  /// missing. Callers keep working: the app is still useful without reminders.
  static Future<bool> requestPermission() async {
    if (!await initialize()) {
      return false;
    }
    return _guard('requestPermission', _requestPermission);
  }

  static Future<bool> _requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) => _guard('schedule', () async {
    await _scheduleOne(id: id, title: title, body: body, when: when);
    return true;
  });

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(when, tz.local),
    notificationDetails: _details,
    // Inexact on purpose: an exact alarm needs a separate permission on
    // Android 14+, and a payment reminder does not need to the second.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Cobros próximos',
      channelDescription: 'Aviso antes de cada cobro de suscripción',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> cancelAll() =>
      _guard('cancelAll', () async => _plugin.cancelAll().then((_) => true));

  /// Whether the user has notifications switched on for the app, without
  /// prompting. Null when the platform cannot answer.
  static Future<bool?> isEnabled() async {
    if (!await initialize()) {
      return false;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return android.areNotificationsEnabled();
    }
    final NotificationAppLaunchDetails? launch = await _plugin
        .getNotificationAppLaunchDetails();
    // iOS has no "are they on" query here; reaching the plugin at all is the
    // only thing this can honestly report.
    return launch == null ? null : true;
  }

  /// What the OS is actually holding. The count the scheduler *planned* and the
  /// count the system *kept* are different numbers, and only this one matters.
  static Future<int> pendingCount() async {
    if (!await initialize()) {
      return 0;
    }
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    return pending.length;
  }

  /// Two notifications that answer two different questions, because a single
  /// one cannot tell them apart:
  ///
  /// - one **now**, straight to the notification manager: does this app have
  ///   permission and a working channel at all?
  /// - one **scheduled**, down the exact path a real reminder takes: does the
  ///   alarm come back and get drawn?
  ///
  /// The first arriving without the second is the signature of a broken alarm
  /// path — a missing receiver, or the system holding the alarm back.
  ///
  /// Scheduling is inexact by design, so the second one is not punctual. Debug
  /// only — see the caller.
  static Future<void> probe(Duration delay) => _guard('probe', () async {
    await _plugin.show(
      id: _probeNowId,
      title: 'Prueba 1 de 2 · inmediata',
      body: 'El permiso y el canal funcionan.',
      notificationDetails: _details,
    );
    await _scheduleOne(
      id: _probeLaterId,
      title: 'Prueba 2 de 2 · programada',
      body: 'La alarma también. Los avisos funcionan en este teléfono.',
      when: DateTime.now().add(delay),
    );
    return true;
  });

  /// Fixed and far from the hashed schedule ids, so a probe replaces the
  /// previous probe and never a real reminder.
  static const int _probeNowId = 2147483646;
  static const int _probeLaterId = 2147483645;

  /// One place where an unavailable platform channel stops being an exception
  /// and becomes a logged false. Without it a missing plugin takes down the
  /// whole app over a feature the user can live without.
  static Future<bool> _guard(
    String action,
    Future<bool> Function() body,
  ) async {
    try {
      return await body();
    } on MissingPluginException {
      developer.log(
        'notifications unavailable ($action) — full restart needed after '
        'adding the plugin',
        name: 'LocalNotificationService',
      );
      return false;
    } on PlatformException catch (error) {
      developer.log(
        'notifications refused ($action): ${error.message}',
        name: 'LocalNotificationService',
      );
      return false;
    }
  }
}
