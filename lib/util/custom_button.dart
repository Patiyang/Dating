// ignore: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hookup4u/util/styling.dart';


class CustomFlatButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final Color iconColor;
  final VoidCallback callback;
  final double height;
  final double width;
  final double radius;
  final double iconSize;
  final bool verifying;
  final IconData icon;
  final double fontSize;
  final double elevation;

  const CustomFlatButton(
      {Key key,
      this.text,
      this.color,
      @ required this.callback,
      this.textColor,
      this.height,
      this.width,
      this.radius,
      this.icon,
      this.fontSize,
      this.iconColor,
      this.iconSize,
      this.verifying = false, this.elevation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: MaterialButton(
        elevation: elevation??1,
        height: height ?? 50,
        minWidth: width ?? 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius??25))),
        onPressed: verifying == true
            ? () {
                Fluttertoast.showToast(msg: 'Please wait');
              }
            : callback,
        color: color ?? ( grey.shade700 ),
        child: Container(
          width: width ?? 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // icon == null
              //     ? SizedBox.shrink()
              //     : Icon(
              //         icon,
              //         size: iconSize ?? 17,color: white,
              //       ),
              // icon == null
              //     ? SizedBox.shrink()
              //     : SizedBox(
              //         width: 0,
              //       ),
              Expanded(
                child: verifying == true
                    ? Container(
                      height: height,
                      child: SpinKitChasingDots(color:white, size: 18))
                    : Text(
                     text==null?'action': text,
                     style: TextStyle(     color: textColor,
                        fontSize: fontSize,                        fontWeight: FontWeight.bold,
),
                   
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
