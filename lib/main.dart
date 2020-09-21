import 'dart:io';
import 'package:sendsms/sendsms.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(
  home: MyLoginPage(),
  theme: ThemeData.dark(),
  debugShowCheckedModeBanner: false,
));

List<String> recipents = [];
SharedPreferences logindata;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _outputs;
  File _image;
  bool _loading = false;
  bool saved = false;
  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Invalid Photo Excluder'),
      // ),
      backgroundColor: Colors.black,
      body: _loading
          ? Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      )
          : Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Container()
                : Container(
              child: Image.file(_image,
                height: MediaQuery.of(context).size.height /2,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            _outputs != null
                ? Text(
              "$_outputs",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                background: Paint()..color = Colors.white,
              ),
            )
                : Container()
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          // new Padding(
          //   padding: EdgeInsets.all(10),
          //   child: Align(
          //     alignment: Alignment.bottomLeft,
          //     child: FloatingActionButton(
          //       heroTag: "btn2",
          //       child: Icon(Icons.pages),
          //       tooltip: 'Login Page',
          //       backgroundColor: Colors.black,
          //       onPressed: () {
          //         Navigator.push(context,
          //             MaterialPageRoute(builder: (context) => MyLoginPage()));
          //       },
          //     ),
          //   ),
          // ),
          new Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                heroTag: "btn1",
                child: Icon(Icons.image),
                tooltip: 'Pick Image from Gallery',
                backgroundColor: Colors.purpleAccent,
                onPressed: pickImage,
              ),
            ),
          ),
          new Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                heroTag: "btn3",
                child: Icon(Icons.camera),
                backgroundColor: Colors.redAccent,
                tooltip: 'Click Image using Camera',
                onPressed: clickImage,
              ),
            ),
          )
        ],
      ),
    );
  }

  clickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    saved = false;
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    saved = true;
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    print(output);
    var t = output[0];
    String x = t['label'];
    print(x);
    setState(() {
      _loading = false;
      _outputs = x;
    });

    if (x == "Safe")
    {
      if(saved == false)
      {
        image = await FlutterExifRotation.rotateAndSaveImage(path: image.path);
      }
    }
    else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String number1 = prefs.getString('number1');
      String number2 = prefs.getString('number2');
      String user= prefs.getString('username');
      recipents.add(number1);
      recipents.add(number2);
      String message = user+ " has clicked an inappropriate image. Please contact them asap.";
      String number1_toSend = recipents[0].toString();
      String number2_toSend = recipents[1].toString();
      await Sendsms.onSendSMS(number1_toSend.toString(), message);
      await Sendsms.onSendSMS(number2_toSend.toString(), message);

      print("\n\n\n\n\n\n");
      print(number1_toSend);
      print(number2_toSend);
      print("\n\n\n\n\n\n");
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}

class MyLoginPage extends StatefulWidget {
  @override
  _MyLoginPageState createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final username_controller = TextEditingController();
  final number1_controller = TextEditingController();
  final number2_controller = TextEditingController();
  bool newuser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    check_if_already_login();
  }

  void check_if_already_login() async {
    logindata = await SharedPreferences.getInstance();
    newuser = (logindata.getBool('login') ?? true);
    print(newuser);
    if (newuser == false) {
      Navigator.pushReplacement(
          context, new MaterialPageRoute(builder: (context) => MyApp()));
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    username_controller.dispose();
    number1_controller.dispose();
    number2_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(" Shared Preferences"),
      // ),
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).copyWith().size.height / 5,
            ),
            Image.asset('assets/images/logo.png'),
            Text(
              "                       ",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: username_controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: number1_controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Parent Number 1',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: number2_controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Parent Number 2',
                ),
              ),
            ),
            RaisedButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () async {
                String username= username_controller.text;
                String number1 = number1_controller.text;
                String number2 = number2_controller.text;
                if ((number1 != '' && number2 != '')&&(number1.length==10 || number1.length==11)&&(number2.length==10 || number2.length==11)) {
                  if (await Permission.sms.request().isGranted) {
                    // Either the permission was already granted before or the user just granted it.
                    print('Successfull');
                    logindata.setBool('login', false);
                    logindata.setString('username', username);
                    logindata.setString('number1', number1);
                    logindata.setString('number2', number2);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyApp()));
                  }
                }
              },
              child: Text("Log-In"),
            ),
          ],
        ),
      ),
    );
  }
}
