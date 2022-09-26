import 'package:flutter/material.dart';

class CustomSnackbar {
  static snackbar(String text, GlobalKey<ScaffoldState> _scaffoldKey, BuildContext context) {
    final snackBar = SnackBar(
      content: Text('$text '),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // _scaffoldKey.currentState.showSnackBar(snackBar);
  }
}
