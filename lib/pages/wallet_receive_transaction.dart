import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toast/toast.dart';

class WalletReceiveTransactionPage extends StatefulWidget {
  WalletReceiveTransactionPage({Key key}) : super(key: key);

  @override
  _WalletReceiveTransactionPageState createState() =>
      _WalletReceiveTransactionPageState();
}

class _WalletReceiveTransactionPageState
    extends State<WalletReceiveTransactionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('收款'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 10,
            ),
            QrImage(
              data: WalletDataCenter.getInstance().accountAddress,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  WalletDataCenter.getInstance().accountAddress,
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
                IconButton(
                  color: Colors.grey,
                  icon: Image.asset('assets/images/copy_icon.png'),
                  onPressed: () {
                    ClipboardData data = ClipboardData(
                        text: WalletDataCenter.getInstance().accountAddress);
                    Clipboard.setData(data).then((value) {
                      Toast.show("已复制", context,
                          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                    });
                  },
                )
              ],
            )
          ],
        ));
  }
}
