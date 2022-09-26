import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hookup4u/Screens/Profile/profile.dart';
import 'package:hookup4u/Screens/Splash.dart';
import 'package:hookup4u/Screens/blockUserByAdmin.dart';
import 'package:hookup4u/Screens/notifications.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'Calling/incomingCall.dart';
import 'Chat/home_screen.dart';
import '../models/call_model.dart';
import 'Home.dart';
import 'package:hookup4u/util/color.dart';
import 'Calling/pickupscreen.dart';

List likedByList = [];

class Tabbar extends StatefulWidget {
  final bool isPaymentSuccess;
  final String plan;
  Tabbar(this.plan, this.isPaymentSuccess);
  @override
  TabbarState createState() => TabbarState();
}

//_
class TabbarState extends State<Tabbar> {
  FirebaseMessaging _firebaseMessaging;
  CollectionReference docRef = FirebaseFirestore.instance.collection('Users');
  auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  User currentUser;
  List<User> matches = [];
  List<User> newmatches = [];

  List<User> users = [];

  /// Past purchases
  List<PurchaseDetails> purchases = [];
  // InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;
  bool isPuchased = false;
  listenCall() {
    auth.User user = _firebaseAuth.currentUser;

    FirebaseFirestore.instance.collection("calls").doc(user.uid).snapshots().listen((doc) {
      if (doc.data != null) {
        var call = CallModel.fromMap(doc.data());
        if (call.calling) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PickupScreen(call: call)));
        }

        //  var data=doc.data;
        // String type=  data['callType'];
        // bool calling=data['calling'];
        // String response=data['response'];
        // String channelId=data['channel_id'];
        //  Map callInfo = {};
        //   callInfo['channel_id'] = message['channel_id'];
        //   callInfo['senderName'] = message['senderName'];
        //   callInfo['senderPicture'] = message['senderPicture'];

      }
    });
  }

  @override
  void initState() {
    super.initState();
    listenCall();
    // Show payment success alert.
    if (widget.isPaymentSuccess != null && widget.isPaymentSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.success,
          title: "Confirmation",
          desc: "You have successfully subscribed to our ${widget.plan} plan.",
          buttons: [
            DialogButton(
              child: Text(
                "Ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    } else {
      print(widget.isPaymentSuccess);
    }
    _getAccessItems();
    _getpastPurchases();
    _getCurrentUser();
    _getMatches();
  }

  Map items = {};
  _getAccessItems() async {
    FirebaseFirestore.instance.collection("Item_access").snapshots().listen((doc) {
      if (doc.docs.length > 0) {
        items = doc.docs[0].data();
        print('the items are ' + doc.docs[0].data.toString());
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _getpastPurchases() async {
    print('in past purchases');
    
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();
    print('response   ${response.pastPurchases.length}');
    for (PurchaseDetails purchase in response.pastPurchases) {
      // if (Platform.isIOS) {
      await _iap.completePurchase(purchase);
      // }
    }
    setState(() {
      purchases = response.pastPurchases;
    });
    if (response.pastPurchases.length > 0) {
      purchases.forEach((purchase) async {
        print('   ${purchase.productID}');
        await _verifyPuchase(purchase.productID);
      });
    }
  }

  /// check if user has pruchased
  PurchaseDetails _hasPurchased(String productId) {
    return purchases.firstWhere((purchase) => purchase.productID == productId, orElse: () => null);
  }

  ///verifying pourchase of user
  Future<void> _verifyPuchase(String id) async {
    PurchaseDetails purchase = _hasPurchased(id);
    print('THE PURCHASE STATUS IS' + purchase.status.toString());
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      print('THE PURCHASE id is' + purchase.productID);
      if (Platform.isIOS) {
        await _iap.completePurchase(purchase);
        print('Achats antérieurs........$purchase');
        isPuchased = true;
      }
      await _iap.completePurchase(purchase);
      isPuchased = true;
    } else {
      isPuchased = false;
    }
  }

  int swipecount = 0;
  _getSwipedcount() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = formatter.format(now);
    FirebaseFirestore.instance
        .collection('/Users/${currentUser.id}/CheckedUser')
        .where(
          // 'timestamp',
          // isEqualTo: Timestamp.now().toDate().subtract(Duration(days: 2)),
          'date', isEqualTo: formatted,
        )
        .snapshots()
        .listen((event) {
      print(event.docs.length);
      setState(() {
        swipecount = event.docs.length;
      });
      return event.docs.length;
    });
  }

  configurePushNotification(User user) async {
    // await _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, sound: true, provisional: false, badge: true));
    _firebaseMessaging.requestPermission(alert: true, sound: true, provisional: false, badge: true);
    _firebaseMessaging.getToken().then((token) {
      print(token);
      docRef.doc(user.id).update({
        'pushToken': token,
      });
    });
    FirebaseMessaging.onMessageOpenedApp.listen((event) async{
           print('===============onLaunch$event');
        if (Platform.isIOS && event.data['type'] == 'Call') {
          Map callInfo = {};
          callInfo['channel_id'] = event.data['channel_id'];
          callInfo['senderName'] = event.data['senderName'];
          callInfo['senderPicture'] = event.data['senderPicture'];
          bool iscallling = await _checkcallState(event.data['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            // await Navigator.push(context,
            //     MaterialPageRoute(builder: (context) => Incoming(message)));
          }
        } else if (Platform.isAndroid && event.data['data']['type'] == 'Call') {
          bool iscallling = await _checkcallState(event.data['data']['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => Incoming(event.data['data'])));
          } else {
            print("Timeout");
          }
        }
    });
    FirebaseMessaging.onMessage.listen((event) async{
            var data = event.data['data'];
        print(data);
        if (Platform.isIOS && event.data['type'] == 'Call') {
          Map callInfo = {};
          callInfo['channel_id'] = event.data['channel_id'];
          callInfo['senderName'] = event.data['senderName'];
          callInfo['senderPicture'] = event.data['senderPicture'];
          // await Navigator.push(context,
          //     MaterialPageRoute(builder: (context) => Incoming(callInfo)));
        } else if (Platform.isAndroid && event.data['data']) {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => Incoming(event.data['data'])));
        } else
          print("object");
    });
    // FirebaseMessaging.onBackgroundMessage((message) => null)
    // _firebaseMessaging.configure(
    //   onLaunch: (Map<String, dynamic> message) async {
    //     print('===============onLaunch$message');
    //     if (Platform.isIOS && message['type'] == 'Call') {
    //       Map callInfo = {};
    //       callInfo['channel_id'] = message['channel_id'];
    //       callInfo['senderName'] = message['senderName'];
    //       callInfo['senderPicture'] = message['senderPicture'];
    //       bool iscallling = await _checkcallState(message['channel_id']);
    //       print("=================$iscallling");
    //       if (iscallling) {
    //         // await Navigator.push(context,
    //         //     MaterialPageRoute(builder: (context) => Incoming(message)));
    //       }
    //     } else if (Platform.isAndroid && message['data']['type'] == 'Call') {
    //       bool iscallling = await _checkcallState(message['data']['channel_id']);
    //       print("=================$iscallling");
    //       if (iscallling) {
    //         await Navigator.push(context, MaterialPageRoute(builder: (context) => Incoming(message['data'])));
    //       } else {
    //         print("Timeout");
    //       }
    //     }
    //   },
    //   onMessage: (Map<String, dynamic> message) async {
    //     // print("onmessage$message");
    //     var data = message['data'];
    //     print(data);
    //     if (Platform.isIOS && message['type'] == 'Call') {
    //       Map callInfo = {};
    //       callInfo['channel_id'] = message['channel_id'];
    //       callInfo['senderName'] = message['senderName'];
    //       callInfo['senderPicture'] = message['senderPicture'];
    //       // await Navigator.push(context,
    //       //     MaterialPageRoute(builder: (context) => Incoming(callInfo)));
    //     } else if (Platform.isAndroid && message['data']) {
    //       await Navigator.push(context, MaterialPageRoute(builder: (context) => Incoming(message['data'])));
    //     } else
    //       print("object");
    //   },
    //   onResume: (Map<String, dynamic> message) async {
    //     print('onResume$message');
    //     if (Platform.isIOS && message['type'] == 'Call') {
    //       Map callInfo = {};
    //       callInfo['channel_id'] = message['channel_id'];
    //       callInfo['senderName'] = message['senderName'];
    //       callInfo['senderPicture'] = message['senderPicture'];
    //       bool iscallling = await _checkcallState(message['channel_id']);
    //       print("=================$iscallling");
    //       if (iscallling) {
    //         // await Navigator.push(context,
    //         //     MaterialPageRoute(builder: (context) => Incoming(message)));
    //       }
    //     } else if (Platform.isAndroid && message['data']['type'] == 'Call') {
    //       bool iscallling = await _checkcallState(message['data']['channel_id']);
    //       print("=================$iscallling");
    //       if (iscallling) {
    //         await Navigator.push(context, MaterialPageRoute(builder: (context) => Incoming(message['data'])));
    //       } else {
    //         print("Timeout");
    //       }
    //     }
    //   },
    // );
  }

  _checkcallState(channelId) async {
    bool iscalling = await FirebaseFirestore.instance.collection("calls").doc(channelId).get().then((value) {
      return value.get("calling") ?? false;
    });
    return iscalling;
  }

  _getMatches() async {
    auth.User user = _firebaseAuth.currentUser;
    return FirebaseFirestore.instance.collection('/Users/${user.uid}/Matches').orderBy('timestamp', descending: true).snapshots().listen((ondata) {
      matches.clear();
      newmatches.clear();
      if (ondata.docs.length > 0) {
        ondata.docs.forEach((f) async {
          DocumentSnapshot doc = await docRef.doc(f.get('Matches')).get();
          if (doc.exists) {
            User tempuser = User.fromDocument(doc);
            tempuser.distanceBW = calculateDistance(currentUser.coordinates['latitude'], currentUser.coordinates['longitude'], tempuser.coordinates['latitude'],
                    tempuser.coordinates['longitude'])
                .round();

            matches.add(tempuser);
            newmatches.add(tempuser);
            if (mounted) setState(() {});
          }
        });
      }
    });
  }

  _getCurrentUser() async {
    auth.User user = _firebaseAuth.currentUser;
    return docRef.doc("${user.uid}").snapshots().listen((data) async {
      currentUser = User.fromDocument(data);
      if (mounted) setState(() {});
      users.clear();
      userRemoved.clear();
      getUserList();
      getLikedByList();
      configurePushNotification(currentUser);
      if (!isPuchased) {
        _getSwipedcount();
      }
      return currentUser;
    });
  }

  query() {
    if (currentUser.showGender == 'everyone') {
      return docRef
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange['min']),
          )
          .where('age', isLessThanOrEqualTo: int.parse(currentUser.ageRange['max']))
          .orderBy('age', descending: false);
    } else {
      return docRef
          .where('editInfo.userGender', isEqualTo: currentUser.showGender)
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange['min']),
          )
          .where('age', isLessThanOrEqualTo: int.parse(currentUser.ageRange['max']))
          //FOR FETCH USER WHO MATCH WITH USER SEXUAL ORIENTAION
          // .where('sexualOrientation.orientation',
          //     arrayContainsAny: currentUser.sexualOrientation)
          .orderBy('age', descending: false);
    }
  }

  Future getUserList() async {
    List checkedUser = [];
    FirebaseFirestore.instance.collection('/Users/${currentUser.id}/CheckedUser').get().then((data) {
      checkedUser.addAll(data.docs.map((f) => f['DislikedUser']));
      checkedUser.addAll(data.docs.map((f) => f['LikedUser']));
    }).then((_) {
      query().get().then((data) async {
        if (data.docs.length < 1) {
          print("no more data");
          return;
        }
        users.clear();
        userRemoved.clear();
        for (var doc in data.docs) {
          User temp = User.fromDocument(doc);
          var distance = calculateDistance(
              currentUser.coordinates['latitude'], currentUser.coordinates['longitude'], temp.coordinates['latitude'], temp.coordinates['longitude']);
          temp.distanceBW = distance.round();
          if (checkedUser.any(
            (value) => value == temp.id,
          )) {
          } else {
            if (currentUser.maxDistance == 0) {
              currentUser.maxDistance = 1;
            }
            // if(currentUser.continent==temp.continent && temp.id != currentUser.id &&
            //   !temp.isBlocked){
            //     if(currentUser.maxDistance==0){
            //    users.add(temp);
            //     }else{
            //       if(distance<=currentUser.maxDistance){
            //          users.add(temp);
            //       }
            //     }
            // }
            //

            if (temp.id != currentUser.id && !temp.isBlocked) {
              users.add(temp);
            }
          }
        }
        if (mounted) setState(() {});
      });
    });
  }

  getLikedByList() {
    docRef.doc(currentUser.id).collection("LikedBy").snapshots().listen((data) async {
      likedByList.addAll(data.docs.map((f) => f['LikedBy']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Exit'),
              content: Text('Do you want to exit the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('No'),
                ),
                TextButton(
                  onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                  child: Text('Yes'),
                ),
              ],
            );
          },
        );
      },
      child: Scaffold(
        body: currentUser == null
            ? Center(child: Splash())
            : currentUser.isBlocked
                ? BlockUser()
                : DefaultTabController(
                    length: 4,
                    initialIndex: widget.isPaymentSuccess != null
                        ? widget.isPaymentSuccess
                            ? 0
                            : 1
                        : 1,
                    child: Scaffold(
                        appBar: AppBar(
                          elevation: 0,
                          backgroundColor: primaryColor,
                          automaticallyImplyLeading: false,
                          title: TabBar(
                              labelColor: Colors.white,
                              indicatorColor: Colors.white,
                              unselectedLabelColor: Colors.black,
                              isScrollable: false,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: [
                                Tab(
                                  icon: Icon(
                                    Icons.person,
                                    size: 30,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.whatshot,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.notifications,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.message,
                                  ),
                                )
                              ]),
                        ),
                        body: TabBarView(
                          children: [
                            Center(child: Profile(currentUser, isPuchased, purchases, items)),
                            Center(child: CardPictures(currentUser, users, swipecount, items, isPuchased)),
                            Center(child: Notifications(currentUser)),
                            Center(child: HomeScreen(currentUser, matches, newmatches)),
                          ],
                          physics: NeverScrollableScrollPhysics(),
                        )),
                  ),
      ),
    );
  }
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}
