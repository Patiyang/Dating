import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hookup4u/Screens/Splash.dart';
import 'package:hookup4u/Screens/Tab.dart';
import 'package:hookup4u/Screens/Welcome.dart';
import 'package:hookup4u/Screens/auth/login.dart';
import 'package:hookup4u/util/color.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    InAppPurchase.instance.restorePurchases();
    // InAppPurchaseConnection.enablePendingPurchases();
    runApp(new MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  bool isAuth = false;
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    // handleCameraAndMic('VideoCall');
    _checkAuth();
    // FirebaseAdMob.instance
    //     .initialize(appId: Platform.isAndroid ? androidAdAppId : iosAdAppId);
  }

  Future _checkAuth() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User user = _auth.currentUser;
    print(user);
    if (user != null) {
      await FirebaseFirestore.instance.collection('Users').where('userId', isEqualTo: user.uid).get().then((QuerySnapshot snapshot) async {
        if (snapshot.docs.length > 0) {
          if (snapshot.docs[0].get('location') != null) {
            setState(() {
              isRegistered = true;
              isLoading = false;
            });
          } else {
            setState(() {
              isAuth = true;
              isLoading = false;
            });
          }
          print("loggedin ${user.uid}");
        } else {
          setState(() {
            isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
      ),
      home: isLoading
          ? Splash()
          : isRegistered
              ? Tabbar(null, null)
              : isAuth
                  ? Welcome()
                  : Login(),
    );
  }
}
