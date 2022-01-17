import 'dart:convert';
import 'dart:typed_data';

import 'package:BBCHDWallet/crypto/base32.dart';
import 'package:BBCHDWallet/data/Global.dart';
import 'package:BBCHDWallet/data/wallet_data_center.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_dart_base/ed25519_dart.dart';
import 'package:pointycastle/digests/blake2b.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'dart:convert' show utf8;



class popularize  {
  List<Map<String, dynamic>> ParentReleationData = List<Map<String, dynamic>>();
  List<Map<String, dynamic>> ChildReleationData = List<Map<String, dynamic>>();

  String subSignInfo = '';
  String SharePriveKey='';
  String SharePubKey='';

  @override
  void initState() {
    // print("---------------------------测试数据-------------------------------------");
    // var sub_privkey = '1dc5a5956c2de69f597cf20da70523b024470ae789e1d2bfc157c9605f17a33a';
    // var sub_pubkey = '70147f8485c30dd50fc995f2f0b6a192bed4882be226747a51c7ee9a04d6299e';
    // var sub_address = '1krmxc14txv3n2ykm4vh2q26mqt9a3dqgyaawj3yn1q1rb13z2hrfxzsp';

    // var parent_key = 'e7c5dbf5ff2d8157993fa8e5128791d8fa3c55a70540f3ca2a5bc86542cb5393';
    // var parent_pubkey = '3bdc5190cd3283c81d6b7a186610ce4ada5e81c4f7fcb153b379afc6154d0014';
    // var parent_address = '12g04t5e6nxwv6mxhzkvw90ayv95cw43631x6p7e8gcscv42hvgxqm0z2';

    // var  shared_privkey = '15c02b5f9eb6e516159c230011a87e57757645b53d3534958f910c08feb5c203';
    // var  shared_pubkey = '06c4246621002576ec70545f04f2cb75378e3f1a16eca2c596fc1c64f52e122b';
    // print("----------------------------------------------------------------------");

    createShareKey();
    var subPriveKey = WalletDataCenter.getInstance().accountPrivateKey;
    // subPriveKey='1dc5a5956c2de69f597cf20da70523b024470ae789e1d2bfc157c9605f17a33a';
    // SharePubKey='06c4246621002576ec70545f04f2cb75378e3f1a16eca2c596fc1c64f52e122b';
    // SharePriveKey='15c02b5f9eb6e516159c230011a87e57757645b53d3534958f910c08feb5c203';
    String subSignInfo =  subPopularizeInfo(SharePubKey,SharePriveKey,subPriveKey);

    //上及绑定代码
    // var parentPubKey = WalletDataCenter.getInstance().accountPublicKey;
    // parentPubKey='68e4dca5989876ca64f16537e82d05c103e5695dfaf009a01632cb33639cc530';
    // String parentSignInfo= parentPopularizeInfo(SharePriveKey,parentPubKey);
    // createTransaction(SharePubKey,subSignInfo,parentSignInfo);
  }

  //生成共享公私钥对
  void createShareKey(){
    var words = bip39.generateMnemonic();
    var binaryResult = bip39.mnemonicToSeed(words.trim());
    var shared_privkey = binaryResult.sublist(32);
    SharePriveKey = HEX.encode(shared_privkey);//共享私钥
    var publickey = publicKey(Uint8List.fromList(shared_privkey.reversed.toList()));
    SharePubKey = HEX.encode(publickey.reversed.toList());//共享公钥
  }

  //生成下级被推广信息
  //sharePubKey  共享公钥  sharePriveKey 共享私钥 subPrivateKey 下级私钥
 String subPopularizeInfo(String sharePubKey,String sharePriveKey,String subPrivateKey){
   var forkid = Global.ForkId;
   var sub_sign_str = "DeFiRelation" + forkid + sharePubKey;

   //消息摘要 要用UTF8编码
   var utf8List = utf8.encode(sub_sign_str);
   Blake2bDigest blake2bObject = new Blake2bDigest(digestSize: 32);
   blake2bObject.update(utf8List, 0, utf8List.length);
   Uint8List digestList = new Uint8List(32);
   blake2bObject.doFinal(digestList, 0);
   var digestHex = HEX.encode(digestList);
   print("消息摘要：" + digestHex);

   var subPrivateKeyHex=HEX.decode(subPrivateKey);
   var subPublickey = publicKey(Uint8List.fromList(subPrivateKeyHex.reversed.toList()));
   //签名参数需要十六进制
   var signMsgHex = sign(HEX.decode(digestHex), Uint8List.fromList(subPrivateKeyHex.reversed.toList()), subPublickey);
   var signMsgStr= HEX.encode(signMsgHex);
   print("消息签名："+signMsgStr);

   //二维码信息
   subSignInfo=signMsgStr +'|'+ sharePriveKey +'|'+ HEX.encode(subPublickey.reversed.toList());

   //验证签名
   // bool b = verifySignature(signMsgHex, HEX.decode(digestHex), subPublickey);
   //下级被推广信息
   return signMsgStr;
 }

  //生成上级推广信息
  //subSignInfo 下级签名信息   parentPubKey 上级公钥
  String parentPopularizeInfo(String sharePrivekey,String parentPubKey){
    var sub_sign_str = "DeFiRelation"  + parentPubKey;
    //消息摘要 要用UTF8编码
    var utf8List = utf8.encode(sub_sign_str);
    Blake2bDigest blake2bObject = new Blake2bDigest(digestSize: 32);
    blake2bObject.update(utf8List, 0, utf8List.length);
    Uint8List digestList = new Uint8List(32);
    blake2bObject.doFinal(digestList, 0);
    var digestHex = HEX.encode(digestList);
    print("父级消息摘要：" + digestHex);

    var subSharePriveKeyHex=HEX.decode(sharePrivekey);
    var subSharePublickeyHex = publicKey(Uint8List.fromList(subSharePriveKeyHex.reversed.toList()));
    //签名参数需要十六进制
    var signMsgHex = sign(HEX.decode(digestHex), Uint8List.fromList(subSharePriveKeyHex.reversed.toList()), subSharePublickeyHex);
    var signMsgStr= HEX.encode(signMsgHex);
    print("父级消息签名："+signMsgStr);
    //验证签名
    // bool b = verifySignature(signMsgHex, HEX.decode(digestHex), subPublickey);
    return signMsgStr;
  }
  //创建交易
  //sharePubKey 共享公钥  subSign 下级签名  parentSign 上级签名
  String createTransaction(String sharePubKey,String subSign,String parentSign){
    // sharePubKey='06c4246621002576ec70545f04f2cb75378e3f1a16eca2c596fc1c64f52e122b';
    var sharePubKeyTransform=  HEX.encode(HEX.decode(sharePubKey).reversed.toList());
    print(sharePubKeyTransform);
    String  vchData = sharePubKeyTransform + subSign + parentSign;
    print("vchData:"+vchData);
    return vchData;
  }
}
