import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permissions_plugin/permissions_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garrud Employee Locator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Garrud Employee Locator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TextEditingController _controller;
  String name;
  String username;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    checkLocationPerms();
    getName();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void saveName(name) async {
    var uuid = Uuid();
    String username = uuid.v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isNameStored = await prefs.setString('Name', name);
    bool isUserNameStored = await prefs.setString('user_name', username);
    print('Saved');
    print(isNameStored);
    print(isUserNameStored);
    var response = await http.get('https://garrud-employee-locator.herokuapp.com:3000/' + name + '/' + username);
    print(response.body);
    getName();
  }

  void getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('Name');
    String username = prefs.getString('user_name');
    print(name);
    if(name == '' || name == null) {
      setup(context);
    } else {
      setState(() {
        this.name = name;
        this.username = username;
      });
      checkLocation();
    }
  }

  void checkLocationPerms() async {
    GeolocationStatus geolocationStatus  = await Geolocator().checkGeolocationPermissionStatus();
    if(geolocationStatus == GeolocationStatus.granted) {
      return;
    } else {
      await PermissionsPlugin.requestPermissions([
        Permission.ACCESS_FINE_LOCATION,
        Permission.ACCESS_COARSE_LOCATION
      ]);
      checkLocationPerms();
    }
  }

  void _getUserPosition() async {
    checkLocationPerms();
    Position userLocation = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    sendLocation(userLocation);
  }

  void checkLocation() async {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _getUserPosition();
    });
  }

  void sendLocation(location) async {
    var response = await http.post('https://garrud-employee-locator.herokuapp.com:3000/' + this.name + '/' + this.username, body: jsonEncode(<String, String>{
      'lat': location.latitude.toString(),
      'lng': location.longitude.toString()
    }), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8'
    });
    print(response.body);
  }

  setup(BuildContext context) {
    AlertDialog alert = AlertDialog(
      title: Text("Enter name:"),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: <Widget> [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name'
              ),
              controller: _controller,
            ),
            FlatButton(
              child: Text('Save', style: TextStyle(fontSize: 20.0)), 
              onPressed: () {
                saveName(_controller.text);
                Navigator.of(context, rootNavigator: true).pop('dialog');
              }
            )
          ]
        )
      )
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: new Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () { 
                setup(context);
              },
              child: Text(
                'Setup',
              )
            )
          ],
        ),
      )
    );
  }
}
