import 'package:flutter/material.dart';

class LoadingHud {
  final BuildContext context;

  LoadingHud({this.context});

  void close() {
    Navigator.of(context).pop();
  }

  showProgressDialog(String title) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Flex(
              direction: Axis.horizontal,
              children: <Widget>[
                CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                ),
                Flexible(
                    flex: 8,
                    child: Text(
                      title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          );
        });
  }
}
