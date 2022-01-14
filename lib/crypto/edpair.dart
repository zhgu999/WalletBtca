

import 'dart:typed_data';
import 'package:ed25519_dart_base/ed25519_dart.dart';

class EDPair {

  Uint8List bytes;

  EDPair(Uint8List bytes) {
    this.bytes = bytes;
  }

  Uint8List edPublicKey() {
    return publicKey(bytes);
  }

  void sign() {

  }

  bool verify() {
    return false;
  }


}