import 'package:sqflite/sqflite.dart';

final String tableWalletUTXO = 'walletAccount';
final String columnId = '_id';
final String columnAddress = 'address';
final String columnTxId = 'txid';
final String columnUTXOType = 'UTXOType';
final String columnAmount = 'amount';
final String columnTxTime = 'txTime';

class WalletUTXO {
  int id;
  String txid;
  int utxoType;
  String address;
  num amount;
  int txTime;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTxId: txid,
      columnUTXOType: utxoType,
      columnAddress: address,
      columnAmount: amount,
      columnTxTime: txTime
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  WalletUTXO();

  WalletUTXO.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    txid = map[columnTxId];
    utxoType = map[columnUTXOType];
    address = map[columnAddress];
    amount = map[columnAmount];
    txTime = map[columnTxTime];
  }
}

class WalletUTXOProvider {
  Database db;

  Future _openDB() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + '/UTXO.db';
    if (db == null) {
      await this._open(path);
    }
  }

  Future _open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableWalletUTXO ( 
  $columnId integer primary key autoincrement, 
  $columnTxId text not null,
  $columnAddress text not null,
  $columnAmount REAL not null,
  $columnUTXOType integer not null,
  $columnTxTime integer not null)
''');
    });
  }

  Future<WalletUTXO> insert(WalletUTXO wallet) async {
    await _openDB();
    wallet.id = await db.insert(tableWalletUTXO, wallet.toMap());
    return wallet;
  }

  Future<List<WalletUTXO>> getWalletUTXO(String address) async {
    await _openDB();
    List<Map> maps = await db.query(tableWalletUTXO,
        columns: [
          columnId,
          columnAddress,
          columnTxId,
          columnUTXOType,
          columnAmount,
          columnTxTime
        ],
        where: "$columnAddress = ?",
        whereArgs: [address],orderBy: "txTime desc");
    if (maps.length > 0) {
      var array = List<WalletUTXO>();
      maps.forEach((element) {
        array.add(WalletUTXO.fromMap(element));
      });
      return array;
    }
    return null;
  }

  Future<int> delete(String address) async {
    await _openDB();
    return await db.delete(tableWalletUTXO,
        where: '$columnAddress = ?', whereArgs: [address]);
  }

  Future<int> deleteTx(String address, String txId) async {
    await _openDB();
    return await db.delete(tableWalletUTXO,
        where: '$columnAddress = ? and $columnTxId = ?',
        whereArgs: [address, txId]);
  }

  Future close() async => db.close();
}
