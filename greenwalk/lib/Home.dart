import 'package:firebase_auth/firebase_auth.dart';

/// Flutter code sample for BottomNavigationBar

// This example shows a [BottomNavigationBar] as it is used within a [Scaffold]
// widget. The [BottomNavigationBar] has three [BottomNavigationBarItem]
// widgets and the [currentIndex] is set to index 0. The selected item is
// amber. The `_onItemTapped` function changes the selected item's index
// and displays a corresponding message in the center of the [Scaffold].
//
// ![A scaffold with a bottom navigation bar containing three bottom navigation
// bar items. The first one is selected.](https://flutter.github.io/assets-for-api-docs/assets/material/bottom_navigation_bar.png)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart' as Location;
import 'package:geolocator/geolocator.dart';
import 'package:android_intent/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Authentication.dart';
import 'LocationService.dart';
import 'MainViewModel.dart';
import 'SignIn.dart';
import 'activity.dart';
import 'profile.dart';
import 'feed.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    title: "Greenwalk",
    home: App(),
    debugShowCheckedModeBanner: false,
  ));
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

  int _selectedIndex = 1;
  final List<Widget> _children = [
    ActivityScreen(),
    FeedScreen(),
    ProfileScreen()
  ];

  final PermissionHandler permissionHandler = PermissionHandler();
  Map<PermissionGroup, PermissionStatus> permissions;

  @override
  void initState() {
    super.initState();

    Provider.of<MainViewModel>(context, listen: false).start();
    __init__();
  }

  Future<void> __init__() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString('email') == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Authentication()),
      );
    }
    await requestLocationPermission();
    await requestActivityRecognitionPermission();
  }

  Future<bool> _requestPermission(PermissionGroup permission) async {
    final PermissionHandler _permissionHandler = PermissionHandler();
    var result = await _permissionHandler.requestPermissions([permission]);
    if (result[permission] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

/*Checking if your App has been Given Permission*/
  Future<bool> requestLocationPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.locationAlways);
    if (granted != true) {
      requestLocationPermission();
    }
    debugPrint('requestContactsPermission $granted');
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

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text("GreenWalk"), actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                prefs.remove('email');

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Authentication()),
                );
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

/*
ListView.separated(
padding: const EdgeInsets.all(8),
itemCount: entries.length,
itemBuilder: (BuildContext context, int index){
return Container(
height: 50,
color: Colors.amber[colorCodes[index]],
child: Center(child: Text('Entry ${entries[index]}')),
);
},
separatorBuilder: (BuildContext context, int index) => const Divider(),
)
*/
