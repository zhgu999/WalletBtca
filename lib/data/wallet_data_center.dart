import 'dart:ffi';

import 'package:BBCHDWallet/data/wallet_account_database.dart';

class WalletDataCenter {

  String accountAddress;
  /// 公钥HEX
  String accountPublicKey;
  /// 私钥HEX
  String accountPrivateKey;

  String accountAmount;

  /// 单例对象
  static WalletDataCenter _instance;

  /// 内部构造方法，可避免外部暴露构造函数，进行实例化
  WalletDataCenter._internal();

  factory WalletDataCenter.getInstance() => _getInstance();

  /// 获取单例内部方法
  static _getInstance() {
    // 只能有一个实例
    if (_instance == null) {
      _instance = WalletDataCenter._internal();
    }
    return _instance;
  }

  Future<String> loadAccountInfo() async {
    var db = WalletAccountProvider();
    var account = await db.getWalletAccount();
    accountAddress = account?.first?.publicKeyAddress ?? null;
    accountPrivateKey = account?.first?.privateKey ?? null;
    accountPublicKey = account?.first?.publicKey ?? null;
    return accountAddress;
  }
  
}
