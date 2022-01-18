import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';

void testWords() {
    var privateKey = Uint8List.fromList([
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31
    ]);
    var words = bip39.entropyToMnemonic(HEX.encode(privateKey));
    var ret = "abandon amount liar amount expire adjust cage candy arch gather drum bullet absurd math era live bid rhythm alien crouch range attend journey unaware";
    if (words == ret) {
      print("OK");
    } else {
      print("Err");
    }
  }

void main(List<String> args) {
  testWords();
}