import 'dart:typed_data';
import 'dart:ui';

import 'package:BBCHDWallet/crypto/base32.dart';
import 'package:BBCHDWallet/data/wallet_account_database.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/pages/wallet_tab_home.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:hex/hex.dart';

class RestorePrivateKeyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RestorePrivateKeyState();
  }
}

class _RestorePrivateKeyState extends State<RestorePrivateKeyPage> {
  final int maxPrivateKeyLength = 32;
  TextEditingController _privateKeyEditingController;
  @override
  void initState() {
    super.initState();
    _privateKeyEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('私钥恢复钱包'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10),
              Text(
                '请输入私钥',
                style: TextStyle(fontSize: 15, color: Colors.black),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: _privateKeyEditingController,
                placeholder: "私钥",
              ),
              SizedBox(height: 10),
              Container(
                  alignment: Alignment.center,
                  child: CupertinoButton.filled(
                      child: Text('确定'), onPressed: restoreAction))
            ],
          ),
        ));
  }

  void restoreAction() async {
    var result = _privateKeyEditingController.text;

    if (result.length != maxPrivateKeyLength) {
      var binaryResult = Uint8List.fromList(HEX.decode(result));
      await createAccount(binaryResult);

      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(
              builder: (context) => WalletTabHomePage(
                  accountAddress:
                      WalletDataCenter.getInstance().accountAddress)),
          (route) => false);

      Toast.show("恢复钱包成功", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
    } else {
      Toast.show("私钥长度为32位，请检查位数", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
    }
  }

  Future<bool> createAccount(Uint8List account) async {
    if (account.length < 32) {
      return false;
    }
    var todo = WalletAccountProvider();
    var user = WalletAccount();

    var publickey =
        publicKey(Uint8List.fromList(account.reversed.toList()));

    var address = HEX.encode(publickey.reversed.toList());

    var base32Address = publicKeyString(address);

    user.privateKey = HEX.encode(account);
    user.publicKeyAddress = base32Address;
    user.publicKey = address;

    var result = await todo.insert(user);
    if (result.id > 0) {
      WalletDataCenter.getInstance().accountAddress = base32Address;
      WalletDataCenter.getInstance().accountPublicKey = address;
      WalletDataCenter.getInstance().accountPrivateKey =
          HEX.encode(account);
      return true;
    }
    return false;
  }
}
