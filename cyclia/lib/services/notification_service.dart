import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );
  }

  Future<void> schedulePillReminder(int id, int hour, int minute) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      'Rappel Pilule 💊',
      'Il est temps de prendre votre pilule pour rester protégée.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pill_reminder_channel',
          'Rappels Pilule',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> schedulePeriodReminder(DateTime startDate) async {
    // Schedule for the day before at 9:00 AM
    final reminderDate = startDate.subtract(const Duration(days: 1));
    final tzDate = tz.TZDateTime.from(
      DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0),
      tz.local,
    );

    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notificationsPlugin.zonedSchedule(
      101,
      'Prévision Cyclia 🩸',
      'Vos règles sont prévues pour demain. Prévoyez le nécessaire !',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'period_reminder_channel',
          'Rappels de Cycle',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleOvulationReminder(DateTime ovulationDate) async {
    // Schedule for the day of ovulation at 8:00 AM
    final tzDate = tz.TZDateTime.from(
      DateTime(ovulationDate.year, ovulationDate.month, ovulationDate.day, 8, 0),
      tz.local,
    );

    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notificationsPlugin.zonedSchedule(
      102,
      'Fenêtre Fertile ✨',
      'C\'est votre jour d\'ovulation estimé. Votre fertilité est au maximum.',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fertility_reminder_channel',
          'Rappels Fertilité',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleSosCheckupReminder() async {
    // Schedule for 14 days from now at 10:00 AM
    final now = DateTime.now();
    final checkupDate = now.add(const Duration(days: 14));
    final tzDate = tz.TZDateTime.from(
      DateTime(checkupDate.year, checkupDate.month, checkupDate.day, 10, 0),
      tz.local,
    );

    await _notificationsPlugin.zonedSchedule(
      501,
      'Vérification Cyclia ✨',
      'Il est temps de faire votre suivi de routine pour plus de sérénité.',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sos_checkup_channel',
          'Suivi de Sécurité',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showPromotion(String title, String body) async {
    await _notificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'promo_channel',
          'Promotions & Conseils',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
