import 'dart:convert';

import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/send_transaction.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/data/wallet_utxo_database.dart';
import 'package:BBCHDWallet/widget/loading_hud.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class WalletRevokeVotePage extends StatefulWidget {
  WalletRevokeVotePage(
      {Key key, this.address, this.addressName, this.voteAmount})
      : super(key: key);

  final String address;
  final String addressName;
  final num voteAmount;

  @override
  _WalletRevokeVotePageState createState() => _WalletRevokeVotePageState();
}

class _WalletRevokeVotePageState extends State<WalletRevokeVotePage> {
  TextEditingController _amountEditingController;
  LoadingHud _loadinghud;
  num _voteSum = 0.00;

  @override
  void initState() {
    super.initState();
    _loadinghud = LoadingHud(context: this.context);
    _amountEditingController = TextEditingController();
    this.loadAddressInfo(widget.address);
  }

  void loadAddressInfo(String address) async {
    try {
      var templdateAddress = await SendTransaction().templateAddress(
          address, WalletDataCenter.getInstance().accountAddress);
      if (templdateAddress.length == 0) {
        return;
      }
      var voteRealAddress = templdateAddress["voteaddr"];
      if (voteRealAddress == null) {
        return;
      }
      var response = await Dio().get(
          Global.IpPort+'/GetUTXOByAddress.ashx?addr=' +
              voteRealAddress);
      var jsonResult = jsonDecode(response.data);
      print(jsonResult);
      if (jsonResult is Map<String, dynamic>) {
        var unspents = jsonResult["unspents"];
        
        if (unspents is List) {
          await this.saveUnspents(unspents, voteRealAddress);
        }
        setState(() {
          _voteSum = jsonResult["sum"];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future saveUnspents(List unspents, String address) async {
    unspents.sort((a, b) {
      int time1 = a["time"];
      int time2 = b["time"];
      return time2.compareTo(time1);
    });
    var utxoProvider = WalletUTXOProvider();

    var list = await utxoProvider.getWalletUTXO(address);
    int localLastTime = list?.first?.txTime ?? 0;
    int remoteLastTime = unspents.first["time"] ?? 0;

    // ??????????????????????????????????????????????????????????????????
    if (remoteLastTime < localLastTime) {
      return;
    }

    await utxoProvider.delete(address);

    for (var item in unspents) {
      if (item is Map) {
        var utxo = WalletUTXO();
        utxo.utxoType = item["out"];
        utxo.txid = item["txid"];
        utxo.address = address;
        utxo.amount = item["amount"];
        utxo.txTime = item["time"];
        await utxoProvider.insert(utxo);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('????????????'),
      ),
      body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '????????????',
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
                    '??????????????????',
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Text(
                    '??????$_voteSum BTCA',
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
                      child: Text('??????'), onPressed: sendVote))
            ],
          )),
    );
  }

  var send = SendTransaction();

  void sendVote() async {
    var amount = _amountEditingController.text;

    var amountAccount = num.tryParse(amount) ?? 0;
    if (amountAccount == 0) {
      Toast.show('???????????????????????????', this.context,
          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      return;
    }
    _loadinghud.showProgressDialog('???????????????...');
    send.revokeVoteTransaction(widget.address, amountAccount).then((value) {
      if (value == null) {
        Toast.show("???????????????????????????", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        return;
      }
      _loadinghud.close();
      if (value["code"] != null) {
        var message = value["message"];
        Toast.show("$message", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      } else {
        Toast.show("??????????????????", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        Navigator.of(context).pop();
      }
    });
  }
}
