import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Entities/ActivityClass.dart';
import '../FlutterBlocs/DataBloc.dart';
import '../MainViewModel.dart';
import 'ActivityDetails.dart';
import 'Activity.dart';
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<ProfileScreen> {
  User1 currentUser = new User1(
      email: "Loading",
      password: "Loading",
      username: "Loading",
      gender: "Loading");


  SharedPreferences prefs;



  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);
    SharedPreferences.getInstance().then((value) {
      String email = value.getString('email');

      currentUser = vm.currentUser;
      vm.getUser(email);
    });

    return Scaffold(
      body: Column(children: <Widget>[
        SizedBox(height: 20),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 750),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              SlideTransition(
            child: child,
            position:
                Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset(0.0, 0.0))
                    .animate(animation),
          ),
          child: HeaderSection(context, vm),
        ),
        Expanded(
          child: BuildBody(context, vm),
        )
      ]),
    );
  }

  List<Activity> activities = new List<Activity>();

  Widget BuildBody(BuildContext context, MainViewModel vm) {
    return Container(child: _buildList(context, vm));
  }

  List<Activity> filter(List<Activity> activities) {
    List<Activity> filtered = new List<Activity>();

    for (Activity v in activities) {
      if (v.user_email == currentUser.email) filtered.add(v);
    }
    return filtered;
  }



  Widget _buildList(BuildContext context, MainViewModel vm) {
    User1 cu = vm.currentUser;
    return StreamBuilder(
      // Wrap our widget with a StreamBuilder
        stream: Databloc.getAllActivities,

        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          List<Activity> current = filterByUser(snapshot.data,cu);
          debugPrint(current.toString());
          final vm = Provider.of<MainViewModel>(context);

          return CustomScrollView(primary: false, slivers: <Widget>[
            SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.count(
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: current.map((data) {
                    Color toSelect;
                    if (data.AQI <= 50) {
                      toSelect = Color.fromARGB(100, 16, 204, 10);
                    } else if (data.AQI <= 100 && data.AQI > 50) {
                      toSelect = Color.fromARGB(100, 244, 208, 63);
                    } else if (data.AQI <= 150 && data.AQI > 100) {
                      toSelect = Color.fromARGB(100, 243, 156, 18);
                    } else if (data.AQI <= 200 && data.AQI > 150) {
                      toSelect = Color.fromARGB(100, 231, 76, 60);
                    } else if (data.AQI <= 300 && data.AQI > 200) {
                      toSelect = Color.fromARGB(100, 142, 68, 173);
                    } else if (data.AQI > 300) {
                      toSelect = Color.fromARGB(100, 100, 30, 22);
                    }

                    return GestureDetector(
                      child: _buildListItem(context, data, toSelect),
                      onTap: () {
                        goToDetailsPage(context, data, vm);
                      },
                    );
                  }).toList(),
                ))
          ]);
        });
  }


  goToDetailsPage(BuildContext context, Activity activity, MainViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ActivityDetails(curActivity: activity, vm: vm)),
    );
  }

  Widget _buildListItem(BuildContext context, Activity data, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Center(
              child: Container(
            child: Column(children: <Widget>[
              Row(children: <Widget>[Text("AQI:" + data.AQI.toString(), style: TextStyle(fontWeight: FontWeight.bold))]),

              Row(children: <Widget>[Text(data.date)]),
              Row(children: <Widget>[
                Text(data.distance.toString() + "km"),
              ]),

              Row(children: <Widget>[Text(data.steps.toString() + "Steps")])
            ]),
          ))),
    );
  }

  Widget HeaderSection(BuildContext context, MainViewModel vm) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
              height: 110,
              width: 100,
              child: GestureDetector(
                  onTap: () {
                    _showPicker(context,vm);
                  },
                  child: Container(
                    height: 200,
                    child: currentUser.image_url==null ? Text("Touch to Add Picture") : Image.network(currentUser.image_url),
                  ))),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: currentUser.username==null ? Text("Loading") :Text(
              currentUser.username,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: currentUser.email == null
                  ? Text("Loading", textAlign: TextAlign.center)
                  : Text(currentUser.email, textAlign: TextAlign.center)),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: Text(
              currentUser.gender == "M" ? "Male" : "Female",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<File> _imgFromCamera() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 50);
    return image;
  }

  Future<File> _imgFromGallery() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
    return image;
  }



  void _showPicker(context, MainViewModel vm) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Photo Library'),
                      onTap: () {
                        _imgFromGallery().then((value) {
                          vm.uploadImageToFirebase(context, value);
                        });
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      _imgFromCamera().then(
                          (value) => vm.uploadImageToFirebase(context, value));
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
  List<Activity> filterByUser(List<Activity> temp, User1 currentUser) {
    debugPrint(currentUser.email);
    debugPrint(temp.toString());
    temp.removeWhere((element) => element.user_email!=currentUser.email);
    debugPrint(temp.toString());
    return temp;

  }
}

class User1 {
  String email, username, password, gender;
  String image_url;

  User1({this.email, this.password, this.username, this.gender, this.image_url});

  factory User1.fromMap(Map<dynamic, dynamic> responseData) {
    return User1(
        password: responseData['password'],
        username: responseData['username'],
        gender: responseData['gender'],
        image_url: responseData['image_url']);
  }

}
