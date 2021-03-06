import 'dart:async';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:ynotes/classes.dart';
import 'package:ynotes/main.dart';
import 'package:ynotes/usefulMethods.dart';

import 'UI/screens/agendaPageWidgets/agenda.dart';
import 'UI/screens/logsPage.dart';
import 'UI/utils/fileUtils.dart';
import 'apis/utils.dart';
import 'background.dart';

class LocalNotification {
  static Future<void> scheduleReminder(AgendaEvent event) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(id: 10, channelKey: 'alarm', title: (event.name != "" && event.name != null) ? event.name : "Sans titre", body: event.description),
      actionButtons: [NotificationActionButton(key: "REPLY", label: "FAIT", autoCancel: true, buttonType: ActionButtonType.KeepOnTop), NotificationActionButton(key: "LOL", label: "PAS FAIT", autoCancel: true, buttonType: ActionButtonType.KeepOnTop)],
      schedule: NotificationSchedule(
        initialDateTime: event.start,
      ),
     
    );
  }

  static Future<void> scheduleNotification(Lesson lesson, {bool onGoing = false}) async {
    int minutes = await getIntSetting("lessonReminderDelay");
    var scheduledNotificationDateTime = lesson.start.subtract(Duration(minutes: onGoing ? 5 : minutes));

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      onGoing ? '2007' : '2006',
      'yNotes',
      onGoing ? 'Rappel de cours constant' : 'Rappels de cours',
      importance: Importance.Max,
      priority: Priority.High,
      visibility: NotificationVisibility.Public,
      icon: "clock",
      enableVibration: !onGoing,
      playSound: !onGoing,
      styleInformation: BigTextStyleInformation(''),
      ongoing: onGoing,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    var id = lesson.start.hashCode;
    if (onGoing) {
      id = 333;
    }
    String room = lesson.room;
    if (room == null || room == "") {
      room = "(aucune salle définie)";
    }
    await flutterLocalNotificationsPlugin.schedule(
        id, onGoing ? 'Rappel de cours constant' : 'Rappels de cours', onGoing ? 'Vous êtes en ${lesson.matiere} dans la salle $room' : 'Le cours ${lesson.matiere} dans la salle ${lesson.room} aura lieu dans $minutes minutes', scheduledNotificationDateTime, platformChannelSpecifics);
  }

  static Future<void> showOngoingNotification(Lesson lesson) async {
    var id = 333;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '2007',
      'yNotes',
      'Rappel de cours constant',
      importance: Importance.Low,
      priority: Priority.Low,
      ongoing: true,
      autoCancel: false,
      enableLights: false,
      playSound: false,
      enableVibration: false,
      icon: "tfiche",
      styleInformation: BigTextStyleInformation(''),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    String defaultSentence = "";
    if (lesson != null) {
      defaultSentence = 'Vous êtes en ${lesson.matiere} dans la salle ${lesson.room}';
      if (lesson.room == null || lesson.room == "") {
        defaultSentence = "Vous êtes en ${lesson.matiere}";
      }
    } else {
      defaultSentence = "Vous êtes en pause";
    }

    var sentence = defaultSentence;
    try {
      if (lesson.canceled) {
        sentence = "Votre cours a été annulé.";
      }
    } catch (e) {}
    await flutterLocalNotificationsPlugin.show(id, 'Rappel de cours constant', sentence, platformChannelSpecifics);
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  ///Set an on going notification which is automatically refreshed (online or not) each hour
  static Future<void> setOnGoingNotification({bool dontShowActual = false}) async {
    //Logs for tests
    await logFile("Setting on going notification");
    print("Setting on going notification");
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson> lessons = List();
    var initializationSettingsAndroid = new AndroidInitializationSettings('newgradeicon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: BackgroundService.onSelectNotification);
    await getChosenParser();
    API api = APIManager();
    //Login creds
    String u = await ReadStorage("username");
    String p = await ReadStorage("password");
    String url = await ReadStorage("pronoteurl");
    String cas = await ReadStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, url: url, cas: cas);
      } catch (e) {
        print("Error while logging");
      }
    }
    var date = DateTime.now();
    int week = await get_week(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(HomeworkAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      print("Error while registring adapter");
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("offlineData");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await api.getNextLessons(date);
      } catch (e) {
        print("Error while collecting online lessons. ${e.toString()}");

        Box _offlineBox = await Hive.openBox("offlineData");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    if (await getSetting("agendaOnGoingNotification")) {
      Lesson getActualLesson = getCurrentLesson(lessons);
      if (!dontShowActual) {
        await showOngoingNotification(getActualLesson);
      }

      int minutes = await getIntSetting("lessonReminderDelay");
      await Future.forEach(lessons, (Lesson lesson) async {
        if (lesson.start.isAfter(date)) {
          try {
            await AndroidAlarmManager.oneShotAt(lesson.start.subtract(Duration(minutes: minutes)), lesson.start.hashCode, callback, exact: true, allowWhileIdle: true);

            print("scheduled " + lesson.start.hashCode.toString() + " $minutes minutes before.");
          } catch (e) {
            print("failed " + e.toString());
          }
        }
      });
      try {
        await AndroidAlarmManager.oneShotAt(lessons.last.end.subtract(Duration(minutes: minutes)), lessons.last.end.hashCode, callback, exact: true, allowWhileIdle: true);
        print("Scheduled last lesson");
      } catch (e) {}
      print("Success !");
    }
  }

  static Future<void> cancelOnGoingNotification() async {
    await cancelNotification(333);
    //Make sure notification is deleted by deleting it's channel
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.deleteNotificationChannel("2007");

    print("Cancelled on going notification");
  }

  static Future<void> cancellAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> callback() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson> lessons = List();
    var initializationSettingsAndroid = new AndroidInitializationSettings('newgradeicon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: BackgroundService.onSelectNotification);
    await getChosenParser();
    API api = APIManager();
    //Login creds
    String u = await ReadStorage("username");
    String p = await ReadStorage("password");
    String url = await ReadStorage("pronoteurl");
    String cas = await ReadStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, url: url, cas: cas);
      } catch (e) {
        print("Error while logging");
      }
    }
    var date = DateTime.now();
    int week = await get_week(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(HomeworkAdapter());
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      print("Error while registring adapter");
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("offlineData");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await api.getNextLessons(date);
      } catch (e) {
        print("Error while collecting online lessons. ${e.toString()}");

        Box _offlineBox = await Hive.openBox("offlineData");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    Lesson currentLesson = getCurrentLesson(lessons);
    Lesson nextLesson = getNextLesson(lessons);
    Lesson lesson;
    //Show next lesson if this one is after current datetime
    if (nextLesson != null && nextLesson.start.isAfter(DateTime.now())) {
      if (await getSetting("enableDNDWhenOnGoingNotifEnabled")) {
        if (await FlutterDnd.isNotificationPolicyAccessGranted) {
          await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_NONE); // Turn on DND - All notifications are suppressed.
        } else {
          await logFile("Couldn't enabled DND");
        }
      }
      lesson = nextLesson;
      await showOngoingNotification(lesson);
    } else {
      if (await getSetting("disableAtDayEnd")) {
        await cancelOnGoingNotification();
      } else {
        lesson = currentLesson;
        await showOngoingNotification(lesson);
      }
    }
    //Logs for tests
    if (lesson != null) {
      await logFile("Persistant notification next lesson callback triggered for the lesson ${lesson.codeMatiere} ${lesson.room}");
    } else {
      await logFile("Persistant notification next lesson callback triggered : you are in break.");
    }
  }
}
