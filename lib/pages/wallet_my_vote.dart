import 'dart:convert';

import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/pages/wallet_revoke_vote.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:toast/toast.dart';

class WalletMyVotePage extends StatefulWidget {
  WalletMyVotePage({Key key, this.address}) : super(key: key);

  final String address;
  @override
  _WalletMyVoteState createState() => _WalletMyVoteState();
}

class _WalletMyVoteState extends State<WalletMyVotePage> {
  // 已投票数据
  List<Map<String, dynamic>> _voteRewardData = List<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    this.loadAddressInfo('');
  }

  void loadAddressInfo(String address) async {
    try {
      var response = await Dio().get(
          Global.IpPort+'/getuservotenodes.ashx?addr=${widget.address}');
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
      } else {
        String message = jsonResult["message"];
        if (message != null) {
          Toast.show("$message", context,
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
        title: Text('已投票节点'),
      ),
      body: EasyRefresh(
          onRefresh: () async {
            this.loadAddressInfo('');
          },
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              var item = _voteRewardData[index];
              return createCustomerItem(item, index);
            },
            itemCount: _voteRewardData.length,
          )),
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
        RaisedButton(
            child: Text('撤回投票'),
            onPressed: () {
              String address = item["address"];
              String addressName = item["nodename"];
              num amount = num.tryParse(item["amount"]) ?? 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => WalletRevokeVotePage(
                        address: address,
                        addressName: addressName,
                        voteAmount: amount)),
              );
            }),
        SizedBox(
          width: 10,
        ),
      ],
    ));
  }
}
