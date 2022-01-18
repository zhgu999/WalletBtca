import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:BBCHDWallet/crypto/base32.dart';
import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/send_transaction.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/data/wallet_popularize.dart';
import 'package:BBCHDWallet/data/wallet_utxo_database.dart';
import 'package:BBCHDWallet/pages/wallet_my_vote.dart';
import 'package:BBCHDWallet/pages/wallet_receive_transaction.dart';
import 'package:BBCHDWallet/pages/wallet_send_transaction.dart';
import 'package:BBCHDWallet/pages/wallet_send_vote.dart';
import 'package:BBCHDWallet/pages/wallet_vote_reward.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hex/hex.dart';
import 'package:toast/toast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WalletTabHomePage extends StatefulWidget {
  WalletTabHomePage({Key key, this.accountAddress}) : super(key: key);
  final String accountAddress;

  @override
  State<StatefulWidget> createState() {
    return _WalletTabHomePageState();
  }
}

class _WalletTabHomePageState extends State<WalletTabHomePage> {
  // 历史记录
  List<Map<String, dynamic>> _historyListData = List<Map<String, dynamic>>();

  // 个人账号数据
  Map<String, dynamic> _addressInfoData = Map<String, dynamic>();

  //上下级关系数据
  List<Map<String, dynamic>> _releationData = List<Map<String, dynamic>>();

  //推广算法对象
  var _popularize = new popularize();

  //作为下级的二维码
  String subSignInfo = '';

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
    } else if (index == 0) {
      this.loadAddressInfo(widget.accountAddress);
      this.loadTransctionHistory(widget.accountAddress);
    } else if (index == 2) {
      this.loadPopularizeInfo();
    } else if (index == 3) {
      this.getReleationData();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (_selectedIndex == 1) {
      w = createHodingCoinWidget();
    } else if (_selectedIndex == 0) {
      w = createAddressInfoWidget(_addressInfoData);
    } else if (_selectedIndex == 2) {
      w = createPopularizeWidget();
    } else if (_selectedIndex == 3) {
      w = createReleadtionWidget(_releationData);
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
            title: Text('持币'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            title: Text('分享'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            title: Text('推广'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  void loadAddressInfo(String address) async {
    try {
      String url = Global.IpPort + "listunspent/" + Global.ForkId + "/" + address;
      var response = await Dio().get(url);
      var jsonResult = response.data;
      print(jsonResult);
      if (jsonResult is Map<String, dynamic>) {
        var addresses = jsonResult["addresses"];
        if (addresses is List) {
          var unspents = addresses[0]["unspents"];
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
      var url = Global.IpPort + "transctions/" + address;
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

    var list = await utxoProvider.getWalletUTXO(WalletDataCenter.getInstance().accountAddress);
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

  Widget createHodingCoinWidget() {
    return Scaffold(
        body: Center(
            child: WebView(
              initialUrl: "https://www.jianshu.com/p/f6bccc30cd33",
            )));
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
            Text(item["time"], style: TextStyle(fontSize: 18, color: Colors.grey)),
            Expanded(
              flex: 1,
              child: Text(''),
            ),
            SizedBox(
              width: 54,
            ),
            Image.asset(operate),
            Text(item["amount"], style: TextStyle(fontSize: 20, color: (flag == 2) ? Colors.red[400] : Colors.green[300])),
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
              Padding(padding: EdgeInsets.only(left: 10), child: Text(sum, style: TextStyle(color: Colors.white, fontSize: 30))),
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
                width: 50,
              ),
              RaisedButton(
                child: Text('转账'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WalletSendTransactionPage()),
                  );
                },
              ),
              SizedBox(
                width: 50,
              ),
              RaisedButton(
                child: Text('收款'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WalletReceiveTransactionPage()),
                  );
                },
              ),
              SizedBox(
                width: 50,
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

  void loadPopularizeInfo() {
    _popularize.createShareKey();
    var subPriveKey = WalletDataCenter.getInstance().accountPrivateKey;
    setState(() {
      subSignInfo = _popularize.subPopularizeInfo(_popularize.SharePubKey, _popularize.SharePriveKey, subPriveKey);
    });
  }

  Widget createPopularizeWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 10,
        ),
        QrImage(
          data: '$subSignInfo',
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
              '使用右侧相机扫描下级二维码',
              style: TextStyle(fontSize: 10, color: Colors.black),
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                String barcode = await BarcodeScanner.scan();
                print(barcode);

                List<String> tmp = barcode.split("|").toList();
                var subSignInfo = tmp[0];
                var sharePriveKey = tmp[1];
                var subPublickey = tmp[2];

                var sharePriveKeyHex = HEX.decode(sharePriveKey); //共享私钥
                var publickey = publicKey(Uint8List.fromList(sharePriveKeyHex.reversed.toList()));
                var sharePubKey = HEX.encode(publickey.reversed.toList()); //共享公钥

                String parentSignInfo = _popularize.parentPopularizeInfo(sharePriveKey, WalletDataCenter.getInstance().accountPublicKey);
                var vchData = _popularize.createTransaction(sharePubKey, subSignInfo, parentSignInfo);

                var send = SendTransaction();
                var subAddress = publicKeyString(subPublickey);
                send.sendTransactionCoin("defi-relation", subAddress, 0.01, comment: vchData).then((value) {
                  if (value != null) {
                    if (value["code"] == null) {
                      Toast.show("推广成功", context, duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                      return;
                    } else {
                      Toast.show(value.toString(), context, duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                      return;
                    }
                  }
                  ;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  void getReleationData() async {
    List<Map<String, dynamic>> releationData = new List<Map<String, dynamic>>();

    // var childResponse = await Dio().get(Global.IpPort+'releationByUpper/'+WalletDataCenter.getInstance().accountAddress);
    var url = "http://159.138.123.135:9906/releationByUpper/1632srrskscs1d809y3x5ttf50f0gabf86xjz2s6aetc9h9ewwhm58dj3";
    var childResponse = await Dio().get(url);
    List<Map<String, dynamic>> _childReleationData = childResponse.data.cast<Map<String, dynamic>>();
    if (_childReleationData != null && _childReleationData.length > 0) {
      Map<String, dynamic> map = new Map<String, dynamic>();
      map["address"] = "我的下级";
      releationData.add(map);

      for (int i = 0; i < _childReleationData.length; i++) {
        Map<String, dynamic> map = new Map<String, dynamic>();
        map["address"] = _childReleationData[i]["lower"];
        releationData.add(map);
      }
    }

    url = 'http://159.138.123.135:9906/releationByLower/2krmxc14txv3n2ykm4vh2q26mqt9a3dqgyaawj3yn1q1rb13z2hrfxzsp';
    var parentResponse = await Dio().get(url);
    // var parentResponse = await Dio().get(Global.IpPort+'releationByLower/'+WalletDataCenter.getInstance().accountAddress);
    List<Map<String, dynamic>> _parentReleationData = parentResponse.data.cast<Map<String, dynamic>>();
    if (_parentReleationData != null && _parentReleationData.length > 0) {
      Map<String, dynamic> map = new Map<String, dynamic>();
      map["address"] = "我的上级";
      releationData.add(map);

      for (int i = 0; i < _parentReleationData.length; i++) {
        Map<String, dynamic> map = new Map<String, dynamic>();
        map["address"] = _parentReleationData[i]["upper"];
        releationData.add(map);
      }
    }
    setState(() {
      _releationData = releationData;
    });
  }

  Widget createReleadtionWidget(List<Map<String, dynamic>> releationData) {
    return EasyRefresh(
        onRefresh: () async {
          getReleationData();
        },
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            if (releationData != null && releationData.length > 0) {
              var item = releationData[index];
              return new Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(item["address"], style: TextStyle(fontSize: 15)),
                ),
              ]);
            }
          },
          itemCount: releationData.length,
        ));
  }
}
