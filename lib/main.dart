import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:push_notifications/firebase_options.dart';
import 'package:push_notifications/model/push_notification.dart';
import 'package:push_notifications/screens/notification_screen.dart';
import 'package:push_notifications/widgets/notification_badge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void notification() async {
    // UserCredential userCredential = await FirebaseAuth.instance
    //     .signInWithEmailAndPassword(
    //         email: "whataboutadate@gmail.com", password: "150783p*");

    // UserCredential userCredential = await FirebaseAuth.instance
    //     .createUserWithEmailAndPassword(
    //         email: "whataboutadate@gmail.com", password: "150783p*");
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      firebaseFirestore.collection('notification').doc(uid).set({
        'fcmToken': fcmToken,
      });
    } catch (e) {}
  }

  @override
  void initState() {
    notification();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //initiate firebase messaging
  late final FirebaseMessaging _messaging;
  late int _totalNotificationCounter;

  // model
  PushNotification? _notificationInfo;

  void registerNotification() async {
    // instance of firebase messaging
    _messaging = FirebaseMessaging.instance;
    // three types of state in notification
    // not determined (null), granted (true) and declined (false)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted the permission");

      // main message
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        PushNotification notification = PushNotification(
          title: message.notification!.title,
          body: message.notification!.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );
        setState(() {
          _totalNotificationCounter++;
          _notificationInfo = notification;
        });

        if (notification != null) {
          showSimpleNotification(
            Text(notification.dataTitle ?? notification.title!),
            subtitle: Text(notification.dataBody ?? notification.body!),
            background: Colors.blue,
            leading:
                NotificationBadge(totalNotification: _totalNotificationCounter),
          );
        }
      });
    } else {
      print("User declined or has not accepted the permission");
    }
  }

  checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification!.title,
        body: initialMessage.notification!.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );
      setState(() {
        _totalNotificationCounter++;
        _notificationInfo = notification;
      });
    }
  }

  @override
  void initState() {
    // when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification!.title,
        body: message.notification!.body,
        dataTitle: message.data['title'],
        dataBody: message.data['body'],
      );
      setState(() {
        _totalNotificationCounter++;
        _notificationInfo = notification;
      });
    });
    // normal notification
    registerNotification();
    _totalNotificationCounter = 0;
    //when app is in terminated state
    checkForInitialMessage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "FlutterPushNotification",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 12,
            ),

            // show a notification badge that will count th total notifocation that  we receive
            NotificationBadge(totalNotification: _totalNotificationCounter),
            const SizedBox(
              height: 12,
            ),
            //if notificationInfo is not null
            _notificationInfo != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "TITLE: ${_notificationInfo!.dataTitle ?? _notificationInfo!.title}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "BODY: ${_notificationInfo!.dataBody ?? _notificationInfo!.body}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const NotificationScreen())),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
