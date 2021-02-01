import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:greenwalk/Entities/User.dart';
import 'package:greenwalk/FlutterBlocs/DataBloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Authentication.dart';
import '../MainViewModel.dart';
import 'Activity.dart';
import 'Profile.dart';
import 'Feed.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(Phoenix(
    child: MaterialApp(
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.light,
        primaryColor: Colors.green[600],
        accentColor: Colors.cyan[600],
        // Define the default font family.
        fontFamily: 'Georgia',
        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      title: "Greenwalk",
    home: App(),
    debugShowCheckedModeBanner: false,
  )));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(),
      child: MainStatefulWidget(),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MainStatefulWidget extends StatefulWidget {
  MainStatefulWidget({Key key}) : super(key: key);

  @override
  _MainStatefulWidget createState() => _MainStatefulWidget();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MainStatefulWidget extends State<MainStatefulWidget> {
  SharedPreferences prefs;
  bool isUserSignedIn = false;
  String email;
  int _selectedIndex = 1;
  User1 currentUser;

  final PermissionHandler permissionHandler = PermissionHandler();
  Map<PermissionGroup, PermissionStatus> permissions;
  List<Widget> _children = [
  ];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();



  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  String messageTitle = "Empty";
  String notificationAlert = "alert";

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin fltrNotification =new FlutterLocalNotificationsPlugin();
  String task;
  int val;

  @override
  void initState() {
    super.initState();
    var androidInitilize = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSinitilize = new IOSInitializationSettings();
    var initilizationsSettings =
    new InitializationSettings(android: androidInitilize, iOS: iOSinitilize);
    Provider.of<MainViewModel>(context, listen: false).start();



    fltrNotification.initialize(initilizationsSettings).then((value) {
      init_fbMessagin();
      __init__();
    });

  }
  final String serverToken = 'AAAAsG67RJk:APA91bFYWMNa0tYqKhH7P-_pAzI8j60T6lwnPHbCurJYwPZ210YlWPbb37hGchyQSAwy7fOaiyOrxZeCl_HjtoKDaO1-RmEx9mOk4D-vJwJc5tP0XXgZZDwBuT8u9cJ934teXTMci0hT';
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();

    sendAndRetrieveMessage() async {
    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true, provisional: false),
    );

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'this is a body',
            'title': 'this is a title'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          'to': await firebaseMessaging.getToken(),
        },
      ),
    );

    final Completer<Map<String, dynamic>> completer =
    Completer<Map<String, dynamic>>();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        completer.complete(message);
      },
    );

    return completer.future;
  }

  Future<void> __init__() async {
    prefs = await SharedPreferences.getInstance();

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    if (prefs.getString('email') == null) {
      email = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Authentication()),
      );
    }
    email = prefs.getString('email');
    await requestCameraPermission();
    await requestLocationPermission();
    await requestActivityRecognitionPermission();

    setState(() {
      _children = [
        ActivityScreen(),
        FeedScreen(fltrNotification),
        ProfileScreen()
      ];
    });




  }




Future<bool> _requestPermission(PermissionGroup permission) async {
    final PermissionHandler _permissionHandler = PermissionHandler();
    var result = await _permissionHandler.requestPermissions([permission]);
    if (result[permission] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }
  Future<bool> requestCameraPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.camera);
    if (granted != true) {
      requestCameraPermission();
    }
    debugPrint('requestCameraPermission $granted');
    return granted;
  }


/*Checking if your App has been Given Permission*/
  Future<bool> requestLocationPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.locationAlways);
    if (granted != true) {
      requestLocationPermission();
    }
    debugPrint('requestLocationPermission $granted');
    return granted;
  }

  Future<bool> requestActivityRecognitionPermission(
      {Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.activityRecognition);
    if (granted != true) {
      requestActivityRecognitionPermission();
    }
    debugPrint('requestActivityRecognitionPermission $granted');
    return granted;
  }




  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _initialized = false;

  Future<void> init_fbMessagin() async {
    if (!_initialized) {
      // For iOS request permission first.

      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(
              sound: true, badge: true, alert: true, provisional: true));
      _firebaseMessaging.configure();
      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      debugPrint("FirebaseMessaging token: $token");
      addToken();
      _initialized = true;
    }
  }

  Future<void> addToken() async {
    final databaseReference = FirebaseDatabase.instance.reference();
    String token = await _firebaseMessaging.getToken();
    databaseReference.child('tokens').set({
        token:'0'}
        );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text("GreenWalk"), actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                prefs.clear();
                Phoenix.rebirth(context);

              },
              child: Icon(
                Icons.logout,
                size: 26.0,
              ),
            )),
      ]),
      body: IndexedStack(
        children: _children,
        index: _selectedIndex,

      ),
      bottomNavigationBar: BottomNavigationBar(

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.heartbeat),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
