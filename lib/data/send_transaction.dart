import 'dart:convert';
import 'dart:typed_data';
import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/wallet_constant.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:BBCHDWallet/data/wallet_utxo_database.dart';
import 'package:hex/hex.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';

class SendTransaction {
  Uint8List privateKey = Uint8List.fromList(
      HEX.decode(WalletDataCenter.getInstance().accountPrivateKey));

  String myAddress = WalletDataCenter.getInstance().accountAddress;

  // 生成inputs的字符串
  Future<String> generateUnspentsString(List<WalletUTXO> utxos) async {
    var utxoString = '';
    if (utxos == null) {
      return utxoString;
    }
    var index = 0;
    for (var item in utxos) {
      var itemString = '';
      if (index > 0) {
        itemString = "|" + item.txid + ",${item.utxoType}";
      } else {
        itemString = item.txid + ",${item.utxoType}";
      }

      utxoString += itemString;
      index++;
    }
    return utxoString;
  }

  // 生成inputs的字符串
  Future<List<Map<String, dynamic>>> generateUnspentsList(List<WalletUTXO> utxos) async {
    List<Map<String, dynamic>> utxoList = new List<Map<String, dynamic>>();
    var index = 0;
    for (var item in utxos) {
      Map<String, dynamic> map=new Map<String,dynamic>();
      map["txid"]=item.txid;
      map["out"]=item.utxoType;
      utxoList.add(map);
    }
    return utxoList;
  }

  // 查找满足余额的UTXO
  Future<List<WalletUTXO>> generateUnspents(String address, num amount) async {
    var utxoProvider = WalletUTXOProvider();
    var result =
        await utxoProvider.getWalletUTXO(address != null ? address : myAddress);
    var returnResult = List<WalletUTXO>();
    if (result == null || result.length == 0) {
      return returnResult;
    }
    num amountTotal = 0;
    for (var item in result) {
      amountTotal += item.amount;
      returnResult.add(item);
      if (amountTotal >= amount + bbcFee) {
        return returnResult;
      }
    }

    return List<WalletUTXO>();
  }

  /// 撤回投票
  Future<Map> revokeVoteTransaction(String voteAddress, num amount) async {
    var templateAddressResult =
        await this.templateAddress(voteAddress, myAddress);

    if (templateAddressResult.length == 0) {
      return templateAddressResult;
    }

    var voteHex = templateAddressResult["votehex"];
    var voteRealAddress = templateAddressResult["voteaddr"];

    var utxos = await this.generateUnspents(voteRealAddress, amount);
    if (utxos.length == 0) {
      return {"code": -1, "message": "撤回投票余额不足"};
    }
    var utxoString = await this.generateUnspentsString(utxos);

    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var transactionResult = await this.createTransaction(
        voteRealAddress, myAddress, amount, utxoString, timestamp);

    if (transactionResult.length == 0) {
      return transactionResult;
    }
    if (transactionResult["txhex"].length <= 2) {
      return transactionResult;
    }
    var txHex = transactionResult["txhex"]
        .substring(0, transactionResult["txhex"].length - 2);
    var txHash = transactionResult["txhash"];
    var rpk = Uint8List.fromList(privateKey.reversed.toList());
    var public = publicKey(rpk);
    var message = HEX.decode(txHash);
    var signature =
        sign(Uint8List.fromList(message.reversed.toList()), rpk, public);
    var cc = txHex + "82" + voteHex + HEX.encode(signature);
    var broadcastTransactionResult = await sendTransaction(cc);
    if (broadcastTransactionResult != null &&
        broadcastTransactionResult["txid"] != null) {
      await asyncUTXOData(voteRealAddress, broadcastTransactionResult["txid"],
          timestamp, amount, utxos);
    }
    return broadcastTransactionResult;
  }

  /// 发起投票
  Future<Map> sendVoteTransaction(String voteAddress, num amount) async {
    var templateAddressResult =
        await this.templateAddress(voteAddress, myAddress);

    if (templateAddressResult.length == 0) {
      return templateAddressResult;
    }

    var voteHex = templateAddressResult["votehex"];
    var voteRealAddress = templateAddressResult["voteaddr"];

    var utxos = await this.generateUnspents(myAddress, amount);
    if (utxos.length == 0) {
      return {"code": -1, "message": "投票余额不足"};
    }
    var utxoString = await this.generateUnspentsString(utxos);

    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var transactionResult = await this.createTransaction(
        myAddress, voteRealAddress, amount, utxoString, timestamp);

    if (transactionResult.length == 0) {
      return transactionResult;
    }
    if (transactionResult["txhex"].length <= 2) {
      return transactionResult;
    }
    var txHex = transactionResult["txhex"]
        .substring(0, transactionResult["txhex"].length - 2);
    var txHash = transactionResult["txhash"];
    var rpk = Uint8List.fromList(privateKey.reversed.toList());
    var public = publicKey(rpk);
    var message = HEX.decode(txHash);
    var signature =
        sign(Uint8List.fromList(message.reversed.toList()), rpk, public);
    var cc = txHex + "82" + voteHex + HEX.encode(signature);
    var broadcastTransactionResult = await sendTransaction(cc);
    if (broadcastTransactionResult != null &&
        broadcastTransactionResult["txid"] != null) {
      await asyncUTXOData(myAddress, broadcastTransactionResult["txid"],
          timestamp, amount, utxos);
    }
    return broadcastTransactionResult;
  }

  /// 转账
  Future<Map> sendTransactionCoin(String transactionType,String toAddress, num amount,{String comment}) async {
    var utxos = await this.generateUnspents(myAddress, amount);
    if (utxos.length == 0) {
      return {"code": -1, "message": "余额不足"};
    }
    var utxoList = await this.generateUnspentsList(utxos);
    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var mapResult = await this.createTransactionBTCA(transactionType, toAddress, amount, utxoList, timestamp, data: comment);

    if (mapResult.length == 0) {
      return mapResult;
    }
    if (mapResult["txhex"].length <= 2) {
      return mapResult;
    }
    var txHex = mapResult["txhex"];//.substring(0, mapResult["txhex"].length - 2);
    var txHash = mapResult["txhash"];

    // txHex='01000000037ac961000000009fd42c82d2493e5c9bacce1113d4d81d5b6419ec2aa8bd24662537a10000000001d58189844fc9f8327c6b769d058b0368ddfbf002bdaa2e89eedbcb147e76c9610102050027e91a9a0d014584c10aa607b62ba960df8df6cc098b7d214d4e9064b9ab00e1f50500000000102700000000000000';
    // txHash='3bcd04dbba53815476c49a6023021806116f6ffa3df4ec5549df08f2ba4df5b3';

    // var rpk = Uint8List.fromList(privateKey.reversed.toList());
    Uint8List genesisPrivkey = Uint8List.fromList(HEX.decode(WalletDataCenter.getInstance().accountPrivateKey));
    var rpk = Uint8List.fromList(genesisPrivkey.reversed.toList());
    var public = publicKey(rpk);
    var message = HEX.decode(txHash);
    var signature =
        sign(Uint8List.fromList(message.reversed.toList()), rpk, public);
    var txdata = txHex + "40" + HEX.encode(signature);
    print("提交上链："+txdata);

    var url=Global.IpPort+'sendrawtransaction/'+txdata;
    var response = await Dio().get(url);
    var transactionResult = response.data;
    print(transactionResult);

    if (transactionResult != null && transactionResult is String) {
      var transactionResultTmp=transactionResult.toString();
      await asyncUTXOData(myAddress, transactionResultTmp, timestamp, amount, utxos);
      Map<String,dynamic> map =new  Map<String,dynamic>();
      map["txid"]=transactionResult;
      return map;
    }
    return transactionResult;
  }

  // 同步UTXO信息
  Future<void> asyncUTXOData(String address, String txId, int timestamp,
      num amount, List<WalletUTXO> utxos) async {
    var utxoProvider = WalletUTXOProvider();
    num myAmount = 0;
    for (var item in utxos) {
      await utxoProvider.deleteTx(address, item.txid);
      myAmount += item.amount;
    }

    var utxo = WalletUTXO();
    utxo.utxoType = 1;
    utxo.txid = txId;
    utxo.address = address;
    utxo.amount = myAmount - amount - bbcFee;
    utxo.txTime = timestamp;
    await utxoProvider.insert(utxo);
  }

  Future<Map<String, String>> templateAddress(
      String voteAddress, String myAddress) async {
    var url =
        Global.IpPort+ "/getvotetemplateaddr.ashx?dposaddr=${voteAddress}&clientaddr=${myAddress}";
    var response = await Dio().get(url);
    var returnResult = Map<String, String>();

    var jsonResult = jsonDecode(response.data);
    print(jsonResult);
    if (jsonResult["voteaddr"] is String) {
      returnResult["voteaddr"] = jsonResult["voteaddr"];
    }
    if (jsonResult["votehex"] is String) {
      returnResult["votehex"] = jsonResult["votehex"];
    }
    return returnResult;
  }

  //BBC创建交易
  Future<Map<String, dynamic>> createTransaction(
      String from, String toAddress, num amount, String inputs, int timestamp,
      {String data = ''}) async {
    var url = Global.IpPort+"CreateTransaction.ashx";
    Map<String, dynamic> p = Map<String, dynamic>();
    p["from"] = from;
    p["to"] = toAddress;
    p["amount"] = amount;
    p["ts"] = timestamp;
    p["inputs"] = inputs;
    p["txfee"] = bbcFee;
    p["fork"] =Global.ForkId;
    p["data"] = data;
    print("para:$p");
    var jsonData = jsonEncode(p);
    var response = await Dio().post(url, data: jsonData);
    var jsonResult = jsonDecode(response.data);
    print(jsonResult);
    var returnResult = Map<String, dynamic>();
    if (jsonResult["txhex"] is String) {
      returnResult["txhex"] = jsonResult["txhex"];
    }
    if (jsonResult["txhash"] is String) {
      returnResult["txhash"] = jsonResult["txhash"];
    }
    return returnResult.length > 0 ? returnResult : jsonResult;
  }

  //BTCA创建交易
  Future<Map<String, dynamic>> createTransactionBTCA(
      String transactionType, String toAddress, num amount, List<Map<String, dynamic>> utxoList, int timestamp,
      {String data = ''}) async {
    // var url = Global.IpPort+"/CreateTransaction.ashx";
    var url= Global.IpPort+'createtransaction';
    Map<String, dynamic> p = Map<String, dynamic>();
    p["type"] = transactionType;
    p["lockuntil"] = 0;
    p["sendto"] = toAddress;
    p["amount"] = amount;
    p["time"] = timestamp;
    p["vin"] = utxoList;

    if(transactionType=="token"){
      p["txfee"] = bbcFee;
    }else{
      p["txfee"] = bbcFee*3;
    }
    p["anchor"] = Global.ForkId;
    p["data"] = data !=null?data:"";

    var jsonData = jsonEncode(p);
    print("交易数据:"+jsonData);
    var response = await Dio().post(url, data: jsonData);
    print(response.data);
    var jsonResult= new Map<String, dynamic>.from(response.data);
    // var jsonResult = jsonDecode(response.data);
    print("拼装交易后的数据:");
    print(jsonResult);
    var returnResult = Map<String, dynamic>();
    if (jsonResult["tx_hex"] is String) {
      returnResult["txhex"] = jsonResult["tx_hex"];
    }
    if (jsonResult["tx_hash"] is String) {
      returnResult["txhash"] = jsonResult["tx_hash"];
    }
    print(returnResult);
    return returnResult.length > 0 ? returnResult : jsonResult;
  }

  Future<Map> sendTransaction(String txdata) async {
    // var url = Global.IpPort+"/sendtransaction.ashx";
    // Map<String, dynamic> p = Map<String, dynamic>();
    // p["txdata"] = txdata;
    // var response = await Dio().post(url, data: jsonEncode(p));
    // var jsonResult = jsonDecode(response.data);
    // print(jsonResult);

    var url= Global.IpPort+'sendrawtransaction/'+txdata;
    var response = await Dio().get(url);
    var jsonResult = response.data;
    return jsonResult;
  }
}
