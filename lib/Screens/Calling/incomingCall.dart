import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:hookup4u/util/color.dart';
import 'package:shimmer/shimmer.dart';
import '../Tab.dart';
import 'call.dart';
import '../../models/call_model.dart';

class Incoming extends StatefulWidget {
  final CallModel call;
  Incoming(this.call);

  @override
  _IncomingState createState() => _IncomingState();
}

class _IncomingState extends State<Incoming> with TickerProviderStateMixin {
  CollectionReference callRef = FirebaseFirestore.instance.collection("calls");
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer.play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true, // Android only - API >= 28
      volume: 1, // Android only - API >= 28
      asAlarm: false, // Android only - all APIs
    );
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() async {
    _controller.dispose();
    FlutterRingtonePlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   title: Text(
      //     "Incoming Call",
      //     style: TextStyle(color: Colors.red),
      //   ),
      // ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
            stream: callRef.where("channel_id", isEqualTo: "${widget.call.channelId}").snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              // Future.delayed(Duration(seconds: 30), () async {
              //   if (!ispickup) {
              //     await callRef
              //         .document(widget.callInfo['channel_id'])
              //         .updateData({'response': 'Not-answer'});
              //   }
              // Navigator.pop(context);
              // });
              if (!snapshot.hasData) {
                Container();
              } else
                try {
                  if (snapshot.data.docs[0]['calling'])
                    switch (snapshot.data.docs[0]['response']) {
                      //wait for pick the call
                      case "Awaiting":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                snapshot.data.docs[0]['callType'] == "VideoCall" ? "Incoming Video Call" : "Incoming Audio Call",
                                style: TextStyle(color: primaryColor, fontSize: 25, fontWeight: FontWeight.bold),
                              ),
                              AnimatedBuilder(
                                  animation: CurvedAnimation(parent: _controller, curve: Curves.slowMiddle),
                                  builder: (context, child) {
                                    return Container(
                                      height: MediaQuery.of(context).size.height * .3,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          _buildContainer(150 * _controller.value),
                                          _buildContainer(200 * _controller.value),
                                          _buildContainer(250 * _controller.value),
                                          _buildContainer(300 * _controller.value),
                                          //_buildContainer(350 * _controller.value),
                                          // Align(
                                          //     child: Icon(
                                          //   Icons.phone_android,
                                          //   size: 44,
                                          // )),

                                          CircleAvatar(
                                            backgroundColor: Colors.grey,
                                            radius: 60,
                                            child: Center(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(
                                                  60,
                                                ),
                                                child: CachedNetworkImage(
                                                  imageUrl: widget.call.callerPic ?? '',
                                                  useOldImageOnUrlChange: true,
                                                  placeholder: (context, url) => CupertinoActivityIndicator(
                                                    radius: 15,
                                                  ),
                                                  errorWidget: (context, url, error) => Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.error,
                                                        color: Colors.black,
                                                        size: 30,
                                                      ),
                                                      Text(
                                                        "Enable to load",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "${widget.call.callerName} ",
                                    style: TextStyle(color: primaryColor, fontSize: 25, fontWeight: FontWeight.bold),
                                  ),
                                  Shimmer.fromColors(
                                    baseColor: Colors.white,
                                    highlightColor: Colors.black,
                                    child: Text(
                                      "is calling you...",
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    FloatingActionButton(
                                        heroTag: UniqueKey(),
                                        backgroundColor: Colors.green,
                                        child: Icon(
                                          snapshot.data.docs[0]['callType'] == "VideoCall" ? Icons.video_call : Icons.call,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          await callRef.doc(widget.call.channelId).update({'response': "Pickup"});
                                          await FlutterRingtonePlayer.stop();
                                        }),
                                    FloatingActionButton(
                                        heroTag: UniqueKey(),
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.clear, color: Colors.white),
                                        onPressed: () async {
                                          await callRef.doc(widget.call.channelId).update({'response': 'Decline', 'calling': false});
                                          Navigator.pop(context);
                                        })
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        break;
                      // push video page with given channel name
                      case "Pickup":
                        {
                          // Future.delayed(Duration(seconds: 2)).then((value) => {
                          //    Navigator.push(context,
                          // MaterialPageRoute(builder: (_)=>CallPage(
                          //    channelName: widget.call.channelId,
                          //   role: ClientRole.Broadcaster,
                          //   callType: snapshot.data.documents[0]['callType'],
                          // )))
                          // });

                          return CallPage(
                            channelName: widget.call.channelId,
                            role: ClientRole.Broadcaster,
                            callType: snapshot.data.docs[0]['callType'],
                          );
                        }
                        break;
                      //call end
                      default:
                        {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Call ended'),
                          ));
                          // Scaffold.of(context).showSnackBar();
                          print('again');

                          return Container(
                            child: Text("Call Ended..."),
                          );
                        }
                        break;
                    }
                  else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Tabbar(null, null)));
                    return Container();
                  }
                  // else if (!snapshot.data.documents[0]['calling'] &&
                  //     snapshot.data.documents[0]['response'] == "Call_Cancelled") {
                  //   return Container(
                  //     child: Text("Missed call"),
                  //   );
                  // }
                } catch (e) {
                  return Container();
                }

              return Container(
                child: Text("Connecting..."),
              );
            }),
      ),
    );
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(1 - _controller.value),
      ),
    );
  }
}
