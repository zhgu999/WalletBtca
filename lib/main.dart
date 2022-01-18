import 'dart:typed_data';

import 'package:BBCHDWallet/data/wallet_account_database.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/data/wallet_utxo_database.dart';
import 'package:BBCHDWallet/pages/create_account.dart';
import 'package:BBCHDWallet/pages/restore_account.dart';
import 'package:BBCHDWallet/pages/restore_private_key.dart';
import 'package:BBCHDWallet/pages/wallet_tab_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';
import 'package:hex/hex.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'crypto/base32.dart';

void main() {
  runApp(MySlashPage());
}

class MySlashPage extends StatefulWidget {
  MySlashPage({Key key}) : super(key: key);

  @override
  _MySlashPageState createState() => _MySlashPageState();
}

class _MySlashPageState extends State<MySlashPage> {
  // 0: 加载中 1: 没有账号去新建账号 2： 加载已有账号
  int appStatus = 0;

  @override
  void initState() {
    super.initState();

    WalletDataCenter.getInstance().loadAccountInfo().then((value) {
      setState(() {
        if (WalletDataCenter.getInstance().accountAddress == null) {
          appStatus = 1;
        } else {
          appStatus = 2;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (appStatus == 0) {
      widget = Scaffold(
          body: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text('Loading...')
        ],
      )));
    } else if (appStatus == 1) {
      widget = MyHomePage(title: 'BTCA Wallet');
    } else if (appStatus == 2) {
      widget = WalletTabHomePage(
          accountAddress: WalletDataCenter.getInstance().accountAddress);
    }

    return MaterialApp(
        title: 'BTCA Wallet',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: widget);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _testPrivateKey() {
    // var pk1 = secretKey();
    // print(HEX.encode(pk1));
    // print(HEX.encode(pk1).length);

    // print(publicKey(pk1));
    var privateKeyBytes = HEX.decode(
        "698849c72f895d16a435b46eddc2a94696372b8300b2b09c6521d76f90d64564");
    print("698849c72f895d16a435b46eddc2a94696372b8300b2b09c6521d76f90d64564"
        .length);
    createAccount111(Uint8List.fromList(privateKeyBytes));
    // var sk = privateKeyBytes.reversed.toList();
    // print(sk);
    // print(sk.length);
    // var pk = publicKey(Uint8List.fromList(sk));
    // var address = HEX.encode(pk.reversed.toList());

    // print(address);
    // print(publicKeyString(address));
  }

  void createAccount111(Uint8List account) {
    print(account.length);

    var publickey = publicKey(Uint8List.fromList(account.reversed.toList()));

    var address = HEX.encode(publickey.reversed.toList());
    print(address);
    var base32Address = publicKeyString(address);
    print(base32Address);
  }

  void generatePrivateKey() {
    var pk = secretKey();
    print(pk);
    var subPK = pk.sublist(32);

    print(subPK);
    print(subPK.length);

    var publickey = publicKey(Uint8List.fromList(subPK.reversed.toList()));

    var address = HEX.encode(publickey.reversed.toList());

    print(address);
    print(publicKeyString(address));
  }

  void _testSignAndVerify() {
    var message =
        '5e916d6e9712123207165b71e31b94bb20ad4e2aa1c74ce28318c8a92f5aa453';
    var privateKeyBytes = HEX.decode(
        "9df809804369829983150491d1086b99f6493356f91ccc080e661a76a976a4ee");

    var sk = privateKeyBytes.reversed.toList();
    var pk = publicKey(Uint8List.fromList(sk));
    var signature = sign(
        Uint8List.fromList(HEX.decode(message).reversed.toList()),
        Uint8List.fromList(privateKeyBytes),
        Uint8List.fromList(pk));
    print(HEX.encode(signature));
    print("Signature length:${signature.length}");

    var result = verifySignature(signature,
        Uint8List.fromList(HEX.decode(message).reversed.toList()), pk);
    print(result);
  }

  void testSign1() {
    var privatekey = Uint8List.fromList([
      94,
      215,
      67,
      164,
      212,
      30,
      114,
      107,
      23,
      186,
      110,
      228,
      185,
      217,
      195,
      218,
      244,
      21,
      135,
      80,
      217,
      172,
      42,
      239,
      202,
      213,
      159,
      60,
      204,
      161,
      1,
      140
    ]);
    print("Private key:" + HEX.encode(privatekey));
    var publickey = publicKey(Uint8List.fromList(privatekey.reversed.toList()));
    var publickey1 = HEX.encode(publickey.reversed.toList());
    print("Public key:" + publickey1);
    print("Public Address:" + publicKeyString(publickey1));

    var message =
        '00b9c3917a198bc4e584d70d42263c78c2dbc63c5281ad609adc5fd2a4b5ca9a';
    var signture = sign(
        Uint8List.fromList(HEX.decode(message).reversed.toList()),
        Uint8List.fromList(privatekey.reversed.toList()),
        publickey);
    print(HEX.encode(signture));
  }

  void testDB() async {
    var todo = WalletAccountProvider();
    var user = WalletAccount();
    user.privateKey = "11";
    user.publicKeyAddress = "333";
    user.publicKey = "22";

    var result = await todo.insert(user);
    var list = await todo.getWalletAccount();
    list.forEach((element) {
      print(element.toMap());
    });
  }

  void testUTXODB() async {
    var todo = WalletUTXOProvider();

    var user = WalletUTXO();
    user.utxoType = 1;
    user.txid = "11232";
    user.address = "abcd";

    // var result = await todo.insert(user);
    var list = await todo.getWalletUTXO("abcd");
    list.forEach((element) {
      print(element.toMap());
    });
  }

  void testWords() {
    var privateKey = Uint8List.fromList([
      94,
      215,
      67,
      164,
      212,
      30,
      114,
      107,
      23,
      186,
      110,
      228,
      185,
      217,
      195,
      218,
      244,
      21,
      135,
      80,
      217,
      172,
      42,
      239,
      202,
      213,
      159,
      60,
      204,
      161,
      1,
      140
    ]);
    var words = bip39.entropyToMnemonic(HEX.encode(privateKey));
    print(words);
  }

  void createAccount() {
    // this.testWords();
    // this.testDB();
    // this.testUTXODB();
    // print('test');
    // this.testSign1();
    // this._testSignAndVerify();
    // SendTransaction().sendVoteTransaction(
    //     "20m05y08mgm2gpyzcgme1r9vtgy25e9sthkrdrt5daef84nz03t7qhb1a",
    //     "1mcrw37wkah5ph788cxpg9g4vnygvgt85jbe51wqnr2xtzp094bhay59a");
    // this._testPrivateKey();
    // generatePrivateKey();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAccountPage()),
    );
  }

  void restoreAccount() {
    showModalBottomSheet(
        context: this.context,
        builder: (BuildContext context) {
          return SafeArea(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.import_export),
                title: Text("助词恢复钱包"),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RestoreAccountPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.vpn_key),
                title: Text("私钥恢复钱包"),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RestorePrivateKeyPage()),
                  );
                },
              )
            ],
          ));
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CupertinoButton.filled(
                  child: Text('创建钱包'), onPressed: createAccount),
              SizedBox(height: 30),
              CupertinoButton.filled(
                  child: Text('恢复钱包'), onPressed: restoreAccount)
            ],
          ),
        ));
  }
}
