import 'dart:convert';
import 'dart:ffi';

import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/data/wallet_utxo_database.dart';
import 'package:BBCHDWallet/pages/wallet_my_vote.dart';
import 'package:BBCHDWallet/pages/wallet_popularize.dart';
import 'package:BBCHDWallet/pages/wallet_receive_transaction.dart';
import 'package:BBCHDWallet/pages/wallet_send_transaction.dart';
import 'package:BBCHDWallet/pages/wallet_send_vote.dart';
import 'package:BBCHDWallet/pages/wallet_vote_reward.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';

class WalletTabHomePage extends StatefulWidget {
  WalletTabHomePage({Key key, this.accountAddress}) : super(key: key);
  final String accountAddress;
  @override
  State<StatefulWidget> createState() {
    return _WalletTabHomePageState();
  }
}

class _WalletTabHomePageState extends State<WalletTabHomePage> {
  // 投票数据
  List<Map<String, dynamic>> _votelistData = List<Map<String, dynamic>>();
  // 历史记录
  List<Map<String, dynamic>> _historyListData = List<Map<String, dynamic>>();
  // 个人账号数据
  Map<String, dynamic> _addressInfoData = Map<String, dynamic>();

  static const List<int> topConfig = <int>[1, 2, 3];

  String userVote = '';
  String allVote = '';

  @override
  void initState() {
    super.initState();
    this.loadAddressInfo(widget.accountAddress);
    this.loadTransctionHistory(widget.accountAddress);
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      this.loadVoteList();
    } else if (index == 0) {
      this.loadAddressInfo(widget.accountAddress);
      this.loadTransctionHistory(widget.accountAddress);
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WalletPopularize()),
      );

    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (_selectedIndex == 1) {
      w = createVoteWidget(_votelistData);
    } else if(_selectedIndex == 0){
      w = createAddressInfoWidget(_addressInfoData);
    } else if (_selectedIndex == 2){
      // WalletDataCenter.getInstance().accountAddress = '123456789qwertyuiop';
      // w = WalletPopularize();
    }
      return Scaffold(
      appBar: AppBar(
        title: const Text('BTCA Wallet'),
      ),
      body: w,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('首页'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            title: Text('投票'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            title: Text('分享'),
          )
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Future loadVoteList() async {
    try {
      var response = await Dio().get(
          Global.IpPort+ '/getnodevotelist.ashx?addr=${widget.accountAddress}');
      var jsonResult = jsonDecode(response.data);
      print(jsonResult);
      if (jsonResult is Map) {
        setState(() {
          List<dynamic> array = jsonResult["data"];
          userVote = jsonResult["uservote"];
          allVote = jsonResult["allvote"];
          var temp = List<Map<String, dynamic>>();
          for (var item in array) {
            if (item is Map<String, dynamic>) {
              temp.add(item);
            }
          }
          _votelistData = temp;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void loadAddressInfo(String address) async {
    try {

      String url=Global.IpPort+"listunspent/"+Global.ForkId+"/"+address;
      var response = await Dio().get(url);
      var jsonResult = response.data;
      print(jsonResult);
      if (jsonResult is Map<String, dynamic>) {
        var addresses = jsonResult["addresses"];
        if (addresses is List) {
          var unspents=   addresses[0]["unspents"];
          await this.saveUnspents(unspents);
        }
        setState(() {
          _addressInfoData = jsonResult;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void loadTransctionHistory(String address) async {
    try {
      var url =Global.IpPort+"transctions/"+address;
      var response = await Dio().get(url);
      // var jsonResult = jsonDecode(response.data);
      var jsonResult = response.data;
      print(jsonResult);
      if (jsonResult is List<dynamic>) {
        var temp = List<Map<String, dynamic>>();
        for (var item in jsonResult) {
          if (item is Map<String, dynamic>) {
            temp.add(item);
          }
        }
        setState(() {
          _historyListData = temp;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future saveUnspents(List unspents) async {
    unspents.sort((a, b) {
      int time1 = a["time"];
      int time2 = b["time"];
      return time2.compareTo(time1);
    });
    var utxoProvider = WalletUTXOProvider();

    var list = await utxoProvider
        .getWalletUTXO(WalletDataCenter.getInstance().accountAddress);
    int localLastTime = list?.first?.txTime ?? 0;
    int remoteLastTime = unspents.first["time"] ?? 0;

    // 当本地的更新时间大于服务端时，不更新本地数据
    if (remoteLastTime < localLastTime) {
      return;
    }

    await utxoProvider.delete(WalletDataCenter.getInstance().accountAddress);

    for (var item in unspents) {
      if (item is Map) {
        var utxo = WalletUTXO();
        utxo.utxoType = item["out"];
        utxo.txid = item["txid"];
        utxo.address = WalletDataCenter.getInstance().accountAddress;
        utxo.amount = item["amount"];
        utxo.txTime = item["time"];
        await utxoProvider.insert(utxo);
      }
    }
  }

  Widget createAddressInfoWidget(Map<String, dynamic> addressInfoData) {
    return EasyRefresh(
        onRefresh: () async {
          this.loadAddressInfo(widget.accountAddress);
          this.loadTransctionHistory(widget.accountAddress);
        },
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return this.createAddressInfoHeaderWidget(addressInfoData);
            }
            return this.createHistoryItem(_historyListData[index - 1], index);
          },
          itemCount: _historyListData.length + 1,
        ));
  }

  Widget createHistoryItem(Map<String, dynamic> item, int index) {

    print(item["flag"]);
    var flag = item["flag"] ?? 0;

    var operate = "";
    if (flag == 1) {
      operate = "assets/images/amount_vote.png";
    } else if (flag == 2) {
      operate = "assets/images/amount_reduce.png";
    } else if (flag == 3) {
      operate = "assets/images/amount_vote_reduce.png";
    } else if (flag == 4) {
      operate = "assets/images/amount_add.png";
    }
    return Container(
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 10,
            ),
            Text(item["time"],
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Expanded(flex: 1,
              child: Text(''),
            ),
            SizedBox(width: 54,),
            Image.asset(operate),
           
            Text(item["amount"],
                style: TextStyle(
                    fontSize: 20,
                    color: (flag == 2)
                        ? Colors.red[400]
                        : Colors.green[300])),
                   Expanded(
              flex: 3,
              child: Text(''),
            ),
          ],
        ));
  }

  Widget createAddressInfoHeaderWidget(Map<String, dynamic> addressInfoData) {
    var address = addressInfoData["address"] ?? "";
    var sum = addressInfoData["total"] ?? 0.00;
    if (sum is num) {
      sum = sum.toString();
    }
    WalletDataCenter.getInstance().accountAmount = sum;
    return Card(
      color: Colors.black54,
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 10,
          ),
          Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                '总资产',
                style: TextStyle(color: Colors.grey),
              )),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(sum,
                      style: TextStyle(color: Colors.white, fontSize: 30))),
              Text("BTCA", style: TextStyle(color: Colors.white, fontSize: 20))
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 10,
              ),
              RaisedButton(
                child: Text('转账'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WalletSendTransactionPage()),
                  );
                },
              ),
              SizedBox(
                width: 10,
              ),
              RaisedButton(
                child: Text('收款'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WalletReceiveTransactionPage()),
                  );
                },
              ),
              SizedBox(
                width: 10,
              ),
              RaisedButton(
                onPressed: () {
                  print(WalletDataCenter.getInstance().accountAddress);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WalletVoteRewardPage(
                              address:
                                  WalletDataCenter.getInstance().accountAddress,
                            )),
                  );
                },
                child: Text('投票收益'),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget createVoteWidget(List<Map<String, dynamic>> listData) {
    return EasyRefresh(
        onRefresh: () async {
          await this.loadVoteList();
        },
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return createVoteHeader();
            }
            var item = listData[index - 1];
            return createCustomerItem(item, index);
          },
          itemCount: _votelistData.length + 1,
        ));
  }

  Widget createVoteHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的投票:$userVote'),
              Text('全网投票:$allVote '),
            ],
          ),
          RaisedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => WalletMyVotePage(
                          address:
                              WalletDataCenter.getInstance().accountAddress,
                        )),
              );
            },
            child: Text('撤投赎回'),
          )
        ],
      ),
    );
  }

  Widget createCustomerItem(Map<String, dynamic> item, int index) {
    var column = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item["nodename"], style: TextStyle(fontSize: 20)),
          Row(
            children: [
              Text(item["amount"],
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(
                width: 2,
              ),
              Text(item["rate"],
                  style: TextStyle(fontSize: 12, color: Colors.grey[350]))
            ],
          ),
        ]);
    var defalutColor = Colors.black;
    if (topConfig.contains(index)) {
      defalutColor = Colors.deepOrange;
    }
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 10,
        ),
        Text(
          "$index",
          style: TextStyle(fontSize: 18, color: defalutColor),
        ),
        SizedBox(
          width: 10,
        ),
        column,
        Expanded(
          child: Text(''),
        ),
        RaisedButton(
          child: Text('投票'),
          onPressed: () {
            String address = item["address"];
            String addressName = item["nodename"];
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => WalletSendVotePage(
                      address: address, addressName: addressName)),
            );
          },
        ),
        SizedBox(
          width: 10,
        ),
      ],
    ));
  }
}
