// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import "dart:typed_data";
import 'package:flutter_test/flutter_test.dart';
import "package:pointycastle/digests/blake2b.dart";
import 'package:BBCHDWallet/crypto/base32.dart';
import 'package:hex/hex.dart';

String formatBytesAsHexString(Uint8List bytes) {
  var result = new StringBuffer();
  for (var i = 0; i < bytes.lengthInBytes; i++) {
    var part = bytes[i];
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    Blake2bDigest digest = new Blake2bDigest(digestSize : 32);
    digest.reset(); 
    var plainText = new Uint8List(100);
    for (int i = 0; i < 100; i++) {
      plainText[i] = i;
    }
    var out = digest.process(plainText);
    var hexOut = formatBytesAsHexString(out);
    var expectedHexDigestText = "5ac86383dec1db602fdbc2c978c3fe1bf4328fea1e1b495b68be2c3b67ba033b";
    expect(hexOut, equals(expectedHexDigestText));
    //base32转16进制
      var b = base32Decode("965p604xzdrffvg90ax9bk0q3xyqn5zz2vc9zpbe3wdswzazj7d144mm");
      var a = HEX.encode(b);
      var c = "498b63009dfb70f7ee0902ba95cc171f7d7a97ff16d89fd96e1f1b9e7d5f91da";
      expect(a, equals(c));
  });
}
