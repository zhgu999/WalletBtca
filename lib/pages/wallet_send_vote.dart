
import 'package:BBCHDWallet/data/send_transaction.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/widget/loading_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class WalletSendVotePage extends StatefulWidget {
  WalletSendVotePage({Key key, this.address, this.addressName})
      : super(key: key);

  final String address;
  final String addressName;

  @override
  _WalletSendVotePageState createState() => _WalletSendVotePageState();
}

class _WalletSendVotePageState extends State<WalletSendVotePage> {
  TextEditingController _amountEditingController;
  LoadingHud _loadinghud;

  @override
  void initState() {
    super.initState();
    _loadinghud = LoadingHud(context: this.context);
    _amountEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var sum = WalletDataCenter.getInstance().accountAmount ?? 0.00;
    return Scaffold(
      appBar: AppBar(
        title: Text('投票'),
      ),
      body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '投票节点',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
              SizedBox(height: 10),
              Text(
                widget.addressName,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '投票数量',
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Text(
                    '可用$sum BBC',
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
                      child: Text('确定'), onPressed: sendVote))
            ],
          )),
    );
  }

  var send = SendTransaction();

  void sendVote() async {
    var amount = _amountEditingController.text;

    var amountAccount = num.tryParse(amount) ?? 0;
    if (amountAccount == 0) {
      Toast.show('请输入投票数量', this.context,
          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      return;
    }
    _loadinghud.showProgressDialog('投票中...');
    send.sendVoteTransaction(widget.address, amountAccount).then((value) {
      if (value == null) {
        Toast.show("投票异常，检查网络", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        return;
      }
      _loadinghud.close();
      if (value["code"] != null) {
        var message = value["message"];
        Toast.show("投票失败:$message", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      } else {
        Toast.show("投票成功", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        Navigator.of(context).pop();
      }
    });
  }
}
