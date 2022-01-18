import 'package:BBCHDWallet/pages/validate_words.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;

class CreateAccountPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CreateAccountState();
  }
}

class _CreateAccountState extends State<CreateAccountPage> {
  List<String> _words = List<String>();

  @override
  void initState() {
    super.initState();
    var wordsString = bip39.generateMnemonic();
    print(wordsString);
    _words = wordsString.split(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('创建助记词'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  '请牢记助记词，切勿拍照或截屏，请用纸笔抄写助记词并妥善保存，如果丢失神仙也找不回！',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                )),
            SizedBox(height: 10),
            createWordWidget(_words),
            SizedBox(height: 10),
            Container(
                alignment: Alignment.center,
                child: CupertinoButton.filled(
                    child: Text('下一步'), onPressed: nextAction))
          ],
        ));
  }

  void nextAction() {
        Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ValidateWordsPage(words: _words,)),
    );
  }

  Widget createWordWidget(List<String> words) {
    if (words.length < 12) {
      return SizedBox();
    }
    List<Widget> h = List<Widget>();
    for (int i = 0; i < words.length; i += 3) {
      var container = Container(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(words[i], style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Text(
            "${i + 1}",
            style: TextStyle(color: Colors.grey),
          )
        ],
      ), width: 100,) ;
      var container1 = Container(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(words[i + 1], style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Text("${i + 2}", style: TextStyle(color: Colors.grey))
        ],
      ),width: 100,);
      var container2 = Container(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(words[i + 2], style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Text("${i + 3}", style: TextStyle(color: Colors.grey))
        ],
      ),width: 100,);
      var hh = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          container,
          // SizedBox(width: 10),
          container1,
          // SizedBox(width: 10),
          container2
        ],
      );
      h.add(hh);
      h.add(SizedBox(height: 10));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: h);
  }
}
