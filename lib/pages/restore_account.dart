import 'dart:typed_data';
import 'dart:ui';

import 'package:BBCHDWallet/crypto/base32.dart';
import 'package:BBCHDWallet/data/wallet_account_database.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/pages/wallet_tab_home.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:toast/toast.dart';
import 'package:hex/hex.dart';

class RestoreAccountPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RestoreAccountState();
  }
}

class _RestoreAccountState extends State<RestoreAccountPage> {
  final int wordMax = 12;

  List<TextEditingController> _textControllers = List<TextEditingController>();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < wordMax; i++) {
      _textControllers.add(TextEditingController(text: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('助记词恢复钱包'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                '请输入12个单词',
                style: TextStyle(fontSize: 15, color: Colors.black),
                textAlign: TextAlign.left,
              )),
          SizedBox(height: 10),
          createWordWidget(),
          SizedBox(height: 10),
          Container(
              alignment: Alignment.center,
              child: CupertinoButton.filled(
                  child: Text('确定'), onPressed: restoreAction))
        ],
      ),
    );
  }

  void restoreAction() async {
    var result = "";
    for (var text in _textControllers) {
      result += text.text;
      result += " ";
    }
    if (bip39.validateMnemonic(result.trim())) {
      var binaryResult = bip39.mnemonicToSeed(result.trim());
      var accountResult = await createAccount(binaryResult);
      // var accountResult = await createAccount(Uint8List.fromList([]));
      if (accountResult) {
        Toast.show("助记词验证成功", context,
            duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);

        Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(
                builder: (context) => WalletTabHomePage(
                    accountAddress:
                        WalletDataCenter.getInstance().accountAddress)),
            (route) => false);
      } else {
        Toast.show("创建账号失败", context,
            duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
      }
      Toast.show("恢复钱包成功", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
    } else {
      Toast.show("检测助记词失败，请仔细检查", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
    }
  }

  Future<bool> createAccount(Uint8List account) async {
    if (account.length < 32) {
      return false;
    }
    var todo = WalletAccountProvider();
    var user = WalletAccount();

    var subPrivateKey = account.sublist(32);
    // var subPrivateKey = Uint8List.fromList([94, 215, 67, 164, 212, 30, 114, 107, 23, 186, 110, 228, 185, 217, 195, 218, 244, 21, 135, 80, 217, 172, 42, 239, 202, 213, 159, 60, 204, 161, 1, 140]);

    var publickey =
        publicKey(Uint8List.fromList(subPrivateKey.reversed.toList()));

    var address = HEX.encode(publickey.reversed.toList());

    var base32Address = publicKeyString(address);

    user.privateKey = HEX.encode(subPrivateKey);
    user.publicKeyAddress = base32Address;
    user.publicKey = address;

    var result = await todo.insert(user);
    if (result.id > 0) {
      WalletDataCenter.getInstance().accountAddress = base32Address;
      WalletDataCenter.getInstance().accountPublicKey = address;
      WalletDataCenter.getInstance().accountPrivateKey =
          HEX.encode(subPrivateKey);
      return true;
    }
    return false;
  }

  void nextTextFieldFocus(int index) {
    if (index + 1 < _textControllers.length) {
      _textControllers[index + 1].clear();
    }
  }

  Widget createWordWidget() {
    List<Widget> h = List<Widget>();
    for (int i = 0; i < wordMax; i += 3) {
      var hh = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            child: CupertinoTextField(
              controller: _textControllers[i],
              placeholder: "${i + 1}",
            ),
            width: 100,
            height: 45,
          ),
          SizedBox(width: 10),
          Container(
              child: CupertinoTextField(
                controller: _textControllers[i + 1],
                placeholder: '${i + 2}',
              ),
              width: 100,
              height: 45),
          SizedBox(width: 10),
          Container(
              child: CupertinoTextField(
                controller: _textControllers[i + 2],
                placeholder: '${i + 3}',
              ),
              width: 100,
              height: 45)
        ],
      );
      h.add(hh);
      h.add(SizedBox(height: 10));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: h);
  }
}
