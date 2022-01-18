import 'dart:math';
import 'dart:typed_data';

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

class ValidateWordsPage extends StatefulWidget {
  ValidateWordsPage({Key key, this.words}) : super(key: key);
  final List<String> words;
  @override
  State<StatefulWidget> createState() {
    return _ValidateWordsState();
  }
}

class _ValidateWordsState extends State<ValidateWordsPage> {
  String _validWords = "";
  var _validWordsList = List<String>();
  var _randomWordsList = List<String>();
  var _randomWordsListSelect = List<bool>();

  @override
  void initState() {
    super.initState();
    var list = List.from(widget.words);
    while (list.length > 0) {
      var index = Random().nextInt(list.length);
      var word = list.elementAt(index);
      list.removeAt(index);
      _randomWordsList.add(word);
    }
    for (int i = 0; i < _randomWordsList.length; i++) {
      _randomWordsListSelect.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('验证助记词'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _validWords = '';
                  _validWordsList.clear();
                });
              },
            )
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Text(
                  _validWords,
                  style: TextStyle(fontSize: 15, color: Colors.black),
                  textAlign: TextAlign.left,
                )),
            SizedBox(height: 10),
            createWordWidget(_randomWordsList),
            SizedBox(height: 10),
            Container(
                alignment: Alignment.center,
                child: CupertinoButton.filled(
                    child: Text('确定'), onPressed: nextAction))
          ],
        ));
  }

  void nextAction() async {
    String originWords = widget.words.join(" ");
    if (originWords != _validWords.trim()) {
      Toast.show("助记词验证失败", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
      return;
    }
    var result = bip39.validateMnemonic(_validWords.trim());
    if (result) {
      var binaryResult = bip39.mnemonicToSeed(_validWords.trim());
      var accountResult = await createAccount(binaryResult);
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
    } else {
      Toast.show("助记词验证失败", context,
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

    var publickey = publicKey(Uint8List.fromList(subPrivateKey.reversed.toList()));
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

  Widget createWordWidget(List<String> words) {
    if (words.length < 12) {
      return SizedBox();
    }
    List<Widget> h = List<Widget>();
    for (int i = 0; i < words.length; i += 3) {
      bool r1 = _validWordsList.contains(words[i]) && _randomWordsListSelect[i];
      bool r2 = _validWordsList.contains(words[i + 1]) &&
          _randomWordsListSelect[i + 1];
      bool r3 = _validWordsList.contains(words[i + 2]) &&
          _randomWordsListSelect[i + 2];
      var hh = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RaisedButton(
              child: Text(words[i],
                  style:
                      TextStyle(color: r1 ? Colors.grey[100] : Colors.black)),
              onPressed: !r1
                  ? () {
                      setState(() {
                        _validWordsList.add(words[i]);
                        _validWords += words[i];
                        _validWords += " ";
                        _randomWordsListSelect[i] = true;
                      });
                    }
                  : null),
          SizedBox(width: 10),
          RaisedButton(
              child: Text(words[i + 1],
                  style:
                      TextStyle(color: r2 ? Colors.grey[100] : Colors.black)),
              onPressed: !r2
                  ? () {
                      setState(() {
                        _validWordsList.add(words[i + 1]);
                        _validWords += words[i + 1];
                        _validWords += " ";
                        _randomWordsListSelect[i + 1] = true;
                      });
                    }
                  : null),
          SizedBox(width: 10),
          RaisedButton(
              child: Text(words[i + 2],
                  style:
                      TextStyle(color: r3 ? Colors.grey[100] : Colors.black)),
              onPressed: !r3
                  ? () {
                      setState(() {
                        _validWordsList.add(words[i + 2]);
                        _validWords += words[i + 2];
                        _randomWordsListSelect[i + 2] = true;
                        _validWords += " ";
                      });
                    }
                  : null)
        ],
      );
      h.add(hh);
      h.add(SizedBox(height: 10));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: h);
  }
}
