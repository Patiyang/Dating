import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:hookup4u/Screens/Information.dart';
import 'package:hookup4u/Screens/Payment/subscriptions.dart';
import 'package:hookup4u/Screens/Tab.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:hookup4u/util/color.dart';
import 'package:intl/intl.dart';
import 'package:swipe_stack/swipe_stack.dart';

List userRemoved = [];
int countswipe = 1;

class CardPictures extends StatefulWidget {
  final List<User> users;
  final User currentUser;
  final int swipedcount;
  final Map items;
  final bool isPuchased;
  CardPictures(this.currentUser, this.users, this.swipedcount, this.items, this.isPuchased);

  @override
  _CardPicturesState createState() => _CardPicturesState();
}

class _CardPicturesState extends State<CardPictures> with AutomaticKeepAliveClientMixin<CardPictures> {
  // TabbarState state = TabbarState();
  bool onEnd = false;
  // Ads _ads = new Ads();

  GlobalKey<SwipeStackState> swipeKey = GlobalKey<SwipeStackState>();
  @override
  bool get wantKeepAlive => true;
  Widget build(BuildContext context) {
    super.build(context);
    int freeSwipe = widget.items['free_swipes'] != null ? int.parse(widget.items['free_swipes']) : 10;

    bool exceedSwipes = widget.swipedcount >= freeSwipe;
    print(freeSwipe);
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)), color: Colors.white),
        child: ClipRRect(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: exceedSwipes,
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      height: MediaQuery.of(context).size.height * .78,
                      width: MediaQuery.of(context).size.width,
                      child:
                          //onEnd ||
                          widget.users.length == 0
                              ? Align(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircleAvatar(
                                          backgroundColor: secondryColor,
                                          radius: 40,
                                        ),
                                      ),
                                      Text(
                                        "There's no one new around you.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: secondryColor, decoration: TextDecoration.none, fontSize: 18),
                                      )
                                    ],
                                  ),
                                )
                              : SwipeStack(
                                  key: swipeKey,

                                  children: widget.users.map((index) {
                                    // User user;
                                    return SwiperItem(builder: (SwiperPosition position, double progress) {
                                      return Material(
                                          elevation: 5,
                                          borderRadius: BorderRadius.all(Radius.circular(30)),
                                          child: Container(
                                            child: Stack(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.all(Radius.circular(30)),
                                                  child: Swiper(
                                                    customLayoutOption: CustomLayoutOption(
                                                      startIndex: 0,
                                                    ),
                                                    key: UniqueKey(),
                                                    physics: NeverScrollableScrollPhysics(),
                                                    itemBuilder: (BuildContext context, int index2) {
                                                      return Container(
                                                        height: MediaQuery.of(context).size.height * .78,
                                                        width: MediaQuery.of(context).size.width,
                                                        child: Builder(
                                                          builder: (_) {
                                                            var imageUrl = index.imageUrl[index2];
                                                            var defaultImg =
                                                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSxUC64VZctJ0un9UBnbUKtj-blhw02PeDEQIMOqovc215LWYKu&s';
                                                            if (imageUrl == defaultImg) {
                                                              var filename = 'asset/continents/${index.continent}.jpg';
                                                              return Image.asset(
                                                                filename,
                                                                fit: BoxFit.fill,
                                                              );
                                                            }

                                                            return CachedNetworkImage(
                                                              imageUrl: index.imageUrl[index2] ?? "",
                                                              fit: BoxFit.cover,
                                                              useOldImageOnUrlChange: true,
                                                              placeholder: (context, url) => CupertinoActivityIndicator(
                                                                radius: 20,
                                                              ),
                                                              errorWidget: (context, url, error) => Icon(Icons.error),
                                                            );
                                                          },
                                                        ),
                                                        // child: Image.network(
                                                        //   index.imageUrl[index2],
                                                        //   fit: BoxFit.cover,
                                                        // ),
                                                      );
                                                    },
                                                    itemCount: index.imageUrl.length,
                                                    pagination: new SwiperPagination(
                                                        alignment: Alignment.bottomCenter,
                                                        builder: DotSwiperPaginationBuilder(activeSize: 13, color: secondryColor, activeColor: primaryColor)),
                                                    control: new SwiperControl(
                                                      color: primaryColor,
                                                      disableColor: secondryColor,
                                                    ),
                                                    loop: false,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(48.0),
                                                  child: position.toString() == "SwiperPosition.Left"
                                                      ? Align(
                                                          alignment: Alignment.topRight,
                                                          child: Transform.rotate(
                                                            angle: pi / 8,
                                                            child: Container(
                                                              height: 40,
                                                              width: 100,
                                                              decoration:
                                                                  BoxDecoration(shape: BoxShape.rectangle, border: Border.all(width: 2, color: Colors.red)),
                                                              child: Center(
                                                                child: Text("NOPE",
                                                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 32)),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : position.toString() == "SwiperPosition.Right"
                                                          ? Align(
                                                              alignment: Alignment.topLeft,
                                                              child: Transform.rotate(
                                                                angle: -pi / 8,
                                                                child: Container(
                                                                  height: 40,
                                                                  width: 100,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape.rectangle, border: Border.all(width: 2, color: Colors.lightBlueAccent)),
                                                                  child: Center(
                                                                    child: Text("LIKE",
                                                                        style: TextStyle(
                                                                            color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 32)),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : Container(),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 10),
                                                  child: Align(
                                                      alignment: Alignment.bottomLeft,
                                                      child: ListTile(
                                                          onTap: () {
                                                            // _ads.myInterstitial()
                                                            //   ..load()
                                                            //   ..show();
                                                            showDialog(
                                                                barrierDismissible: false,
                                                                context: context,
                                                                builder: (context) {
                                                                  return Info(index, widget.currentUser, swipeKey);
                                                                });
                                                          },
                                                          title: Text(
                                                            "${index.name}, ${index.editInfo['showMyAge'] != null ? !index.editInfo['showMyAge'] ? index.age : "" : index.age}",
                                                            style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
                                                          ),
                                                          subtitle: Text(
                                                            "${index.address} (${index.continent})",
                                                            style: TextStyle(
                                                              color: Colors.black,
                                                              fontSize: 20,
                                                            ),
                                                          ))),
                                                ),
                                              ],
                                            ),
                                          ));
                                    });
                                  }).toList(growable: true),
                                  threshold: 30,
                                  maxAngle: 100,
                                  //animationDuration: Duration(milliseconds: 400),
                                  visibleCount: 5,
                                  historyCount: 1,

                                  stackFrom: StackFrom.Right,
                                  translationInterval: 5,
                                  scaleInterval: 0.08,
                                  onSwipe: (int index, SwiperPosition position) async {
                                    _adsCheck(countswipe);
                                    print(position);
                                    print(widget.users[index].name);
                                    CollectionReference docRef = FirebaseFirestore.instance.collection("Users");
                                    if (position == SwiperPosition.Left) {
                                      final DateTime now = DateTime.now();
                                      final DateFormat formatter = DateFormat('yyyy-MM-dd');
                                      final String formatted = formatter.format(now);
                                      await docRef.doc(widget.currentUser.id).collection("CheckedUser").doc(widget.users[index].id).set(
                                        {
                                          'DislikedUser': widget.users[index].id,
                                          'timestamp': DateTime.now(),
                                          'date': formatted,
                                          // 'day':Timestamp.now().toDate().day,
                                        },
                                      );

                                      if (index < widget.users.length) {
                                        userRemoved.clear();
                                        setState(() {
                                          userRemoved.add(widget.users[index]);
                                          widget.users.removeAt(index);
                                        });
                                      }
                                    } else if (position == SwiperPosition.Right) {
                                      final DateTime now = DateTime.now();
                                      final DateFormat formatter = DateFormat('yyyy-MM-dd');
                                      final String formatted = formatter.format(now);
                                      if (likedByList.contains(widget.users[index].id)) {
                                        showDialog(
                                            context: context,
                                            builder: (ctx) {
                                              Future.delayed(Duration(milliseconds: 1700), () {
                                                Navigator.pop(ctx);
                                              });
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 80),
                                                child: Align(
                                                  alignment: Alignment.topCenter,
                                                  child: Card(
                                                    child: Container(
                                                      height: 100,
                                                      width: 300,
                                                      child: Center(
                                                        child: Text(
                                                          "It's a match\n With ${widget.users[index].name}",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(color: primaryColor, fontSize: 30, decoration: TextDecoration.none),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            });
                                        await docRef.doc(widget.currentUser.id).collection("Matches").doc(widget.users[index].id).set(
                                          {
                                            'Matches': widget.users[index].id,
                                            'isRead': false,
                                            'userName': widget.users[index].name,
                                            'pictureUrl': widget.users[index].imageUrl[0],
                                            'timestamp': FieldValue.serverTimestamp()
                                          },
                                        );
                                        await docRef.doc(widget.users[index].id).collection("Matches").doc(widget.currentUser.id).set(
                                          {
                                            'Matches': widget.currentUser.id,
                                            'userName': widget.currentUser.name,
                                            'pictureUrl': widget.currentUser.imageUrl[0],
                                            'isRead': false,
                                            'timestamp': FieldValue.serverTimestamp()
                                          },
                                        );
                                      }

                                      await docRef.doc(widget.currentUser.id).collection("CheckedUser").doc(widget.users[index].id).set(
                                        {
                                          'LikedUser': widget.users[index].id,
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'date': formatted,
                                        },
                                      );
                                      await docRef.doc(widget.users[index].id).collection("LikedBy").doc(widget.currentUser.id).set(
                                        {'LikedBy': widget.currentUser.id, 'timestamp': FieldValue.serverTimestamp()},
                                      );
                                      if (index < widget.users.length) {
                                        userRemoved.clear();
                                        setState(() {
                                          userRemoved.add(widget.users[index]);
                                          widget.users.removeAt(index);
                                        });
                                      }
                                    } else
                                      debugPrint("onSwipe $index $position");
                                  },
                                  onRewind: (int index, SwiperPosition position) {
                                    swipeKey.currentContext.dependOnInheritedWidgetOfExactType();
                                    widget.users.insert(index, userRemoved[0]);
                                    setState(() {
                                      userRemoved.clear();
                                    });
                                    debugPrint("onRewind $index $position");
                                    print(widget.users[index].id);
                                  },
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            widget.users.length != 0
                                ? FloatingActionButton(
                                    heroTag: UniqueKey(),
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      userRemoved.length > 0 ? Icons.replay : Icons.not_interested,
                                      color: userRemoved.length > 0 ? Colors.amber : secondryColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      if (userRemoved.length > 0) {
                                        swipeKey.currentState.rewind();
                                      }
                                    })
                                : FloatingActionButton(
                                    heroTag: UniqueKey(),
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    onPressed: () {},
                                  ),
                            FloatingActionButton(
                                heroTag: UniqueKey(),
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () {
                                  if (widget.users.length > 0) {
                                    print("object");
                                    swipeKey.currentState.swipeLeft();
                                  }
                                }),
                            FloatingActionButton(
                                heroTag: UniqueKey(),
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.lightBlueAccent,
                                  size: 30,
                                ),
                                onPressed: () {
                                  if (widget.users.length > 0) {
                                    swipeKey.currentState.swipeRight();
                                  }
                                }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              exceedSwipes && widget.isPuchased==false
                  ? Align(
                      alignment: Alignment.center,
                      child: InkWell(
                          child: Container(
                            color: Colors.white.withOpacity(.3),
                            child: Dialog(
                              insetAnimationCurve: Curves.bounceInOut,
                              insetAnimationDuration: Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: Colors.white,
                              child: Container(
                                height: MediaQuery.of(context).size.height * .55,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 50,
                                      color: primaryColor,
                                    ),
                                    GestureDetector(
                                      onTap: () async {

                                        auth.FirebaseAuth fauth = auth.FirebaseAuth.instance;
                                        auth.User user =  fauth.currentUser;
                                        print(user.uid);
                                      },
                                      child: Text(
                                        "you have already used the maximum number of free available swipes for Today.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 20),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 120,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Text(
                                      "For swipe more users just subscribe our premium plans.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Subscription(null, null, widget.items)))),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  void _adsCheck(count) {
    print(count);
    if (count % 5 == 0) {
      // _ads.myInterstitial()
      //   ..load()
      //   ..show();
      countswipe++;
    } else {
      countswipe++;
    }
  }
}
