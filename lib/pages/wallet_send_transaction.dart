import 'package:BBCHDWallet/data/send_transaction.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/widget/loading_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class WalletSendTransactionPage extends StatefulWidget {
  WalletSendTransactionPage({Key key, this.address}) : super(key: key);

  final String address;

  @override
  _WalletTransactionPageState createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletSendTransactionPage> {
  TextEditingController _addressEditingController;
  TextEditingController _amountEditingController;
  // TextEditingController _descriptionEditingController;
  LoadingHud _loadinghud;

  @override
  void initState() {
    super.initState();
    _loadinghud = LoadingHud(context: this.context);
    // _addressEditingController = TextEditingController(
    //     text: "1mg6bk8eah69nj0s7z9vm4rb3svz9qb31n4jsyy74e4gr86pgp44xpqkz");
    _addressEditingController = TextEditingController();
    _amountEditingController = TextEditingController();
    // _descriptionEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var sum = WalletDataCenter.getInstance().accountAmount ?? 0.00;
    return Scaffold(
      appBar: AppBar(
        title: Text('转账'),
      ),
      body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '接收地址',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: _addressEditingController,
                placeholder: "BTCA地址",
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BTCA数量',
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Text(
                    '可用$sum BTCA',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                ],
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: _amountEditingController,
                placeholder: "0.00",
              ),
              SizedBox(height: 10),
              Container(
                  alignment: Alignment.center,
                  child: CupertinoButton.filled(
                      child: Text('确定'), onPressed: sendTransaction))
            ],
          )),
    );
  }

  var send = SendTransaction();

  void sendTransaction() async {
    var amount = _amountEditingController.text;

    var amountAccount = num.tryParse(amount) ?? 0;
    if (amountAccount == 0) {
      Toast.show("金额大于0", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
      return;
    }
    _loadinghud.showProgressDialog('转账中...');
    send.sendTransactionCoin("token",_addressEditingController.text, amountAccount)
        .then((value) {
      if (value == null) {
        Toast.show("转账异常，检查网络", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        return;
      }
      _loadinghud.close();
      if (value["code"] != null) {
        var message = value["message"];
        Toast.show("转账失败:$message", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      } else {
        Toast.show("转账成功", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
            Navigator.of(context).pop();
      }
    });
  }
}
