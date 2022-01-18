import 'package:sqflite/sqflite.dart';

final String tableWalletAccount = 'walletAccount';
final String columnId = '_id';
final String columnPrivateKey = 'privateKey';
final String columnPublicKey = 'publicKey';
final String columnPublicKeyAddress = 'publicKeyAddress';

class WalletAccount {
  int id;
  String privateKey;
  String publicKey;
  String publicKeyAddress;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnPrivateKey: privateKey,
      columnPublicKey: publicKey,
      columnPublicKeyAddress: publicKeyAddress
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  WalletAccount();

  WalletAccount.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    privateKey = map[columnPrivateKey];
    publicKey = map[columnPublicKey];
    publicKeyAddress = map[columnPublicKeyAddress];
  }
}

class WalletAccountProvider {
  Database db;

   Future _openDB() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + '/Account.db';
    if (db == null) {
      await this._open(path);
    }
  }

  Future _open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableWalletAccount ( 
  $columnId integer primary key autoincrement, 
  $columnPrivateKey text not null,
  $columnPublicKey text not null,
  $columnPublicKeyAddress text not null)
''');
    });
  }

  Future<WalletAccount> insert(WalletAccount wallet) async {
    await this._openDB();
    wallet.id = await db.insert(tableWalletAccount, wallet.toMap());
    return wallet;
  }

  Future<List<WalletAccount>> getWalletAccount() async {
    await this._openDB();
    List<Map> maps = await db.query(tableWalletAccount, columns: [
      columnId,
      columnPrivateKey,
      columnPublicKey,
      columnPublicKeyAddress
    ]);
    if (maps.length > 0) {
      var array = List<WalletAccount>();
      maps.forEach((element) {
        array.add(WalletAccount.fromMap(element));
      });
      return array;
    }
    return null;
  }

  Future close() async => db.close();
}
