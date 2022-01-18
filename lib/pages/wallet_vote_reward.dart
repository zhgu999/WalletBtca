import 'dart:convert';

import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:toast/toast.dart';

class WalletVoteRewardPage extends StatefulWidget {
  WalletVoteRewardPage({Key key, this.address}) : super(key: key);

  final String address;
  @override
  _WalletSendVoteRewardState createState() => _WalletSendVoteRewardState();
}

class _WalletSendVoteRewardState extends State<WalletVoteRewardPage> {
  // 投票数据
  List<Map<String, dynamic>> _voteRewardData = List<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    this.loadAddressInfo(widget.address);
  }

  void loadAddressInfo(String address) async {
    try {
      var host = Global.IpPort+"/getrewardlist.ashx";
      var parameters = address != null ? "?clientaddr=$address" : "";
      var response = await Dio().get(host + parameters);
      var jsonResult = jsonDecode(response.data);
      if (jsonResult is List<dynamic>) {
        setState(() {
          var temp = List<Map<String, dynamic>>();
          for (var item in jsonResult) {
            if (item is Map<String, dynamic>) {
              temp.add(item);
            }
          }
          _voteRewardData = temp;
        });
      } else if (jsonResult is Map) {
        var code = jsonResult["code"];
        if (code != null) {
          Toast.show(jsonResult["message"], context,
              duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        }
      }
      print(jsonResult);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('投票收益'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: EasyRefresh(
            onRefresh: () async {
              this.loadAddressInfo(widget.address);
            },
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var item = _voteRewardData[index];
                return createCustomerItem(item, index);
              },
              itemCount: _voteRewardData.length,
            )),
      ),
    );
  }

  Widget createCustomerItem(Map<String, dynamic> item, int index) {
    var column = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item["nodename"], style: TextStyle(fontSize: 20)),
          Text(item["amount"] + " BTCA",
              style: TextStyle(fontSize: 12, color: Colors.grey))
        ]);
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 10,
        ),
        column,
        Expanded(
          child: Text(''),
        ),
        Text(item["date"], style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(
          width: 10,
        ),
      ],
    ));
  }
}
