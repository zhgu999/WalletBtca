
import 'dart:ffi';
import 'dart:typed_data';

const String alphabet = "0123456789abcdefghjkmnpqrstvwxyz";

Uint32List crc24qTable = Uint32List.fromList([
  0x00000000,
  0x01864CFB,
  0x028AD50D,
  0x030C99F6,
  0x0493E6E1,
  0x0515AA1A,
  0x061933EC,
  0x079F7F17,
  0x08A18139,
  0x0927CDC2,
  0x0A2B5434,
  0x0BAD18CF,
  0x0C3267D8,
  0x0DB42B23,
  0x0EB8B2D5,
  0x0F3EFE2E,
  0x10C54E89,
  0x11430272,
  0x124F9B84,
  0x13C9D77F,
  0x1456A868,
  0x15D0E493,
  0x16DC7D65,
  0x175A319E,
  0x1864CFB0,
  0x19E2834B,
  0x1AEE1ABD,
  0x1B685646,
  0x1CF72951,
  0x1D7165AA,
  0x1E7DFC5C,
  0x1FFBB0A7,
  0x200CD1E9,
  0x218A9D12,
  0x228604E4,
  0x2300481F,
  0x249F3708,
  0x25197BF3,
  0x2615E205,
  0x2793AEFE,
  0x28AD50D0,
  0x292B1C2B,
  0x2A2785DD,
  0x2BA1C926,
  0x2C3EB631,
  0x2DB8FACA,
  0x2EB4633C,
  0x2F322FC7,
  0x30C99F60,
  0x314FD39B,
  0x32434A6D,
  0x33C50696,
  0x345A7981,
  0x35DC357A,
  0x36D0AC8C,
  0x3756E077,
  0x38681E59,
  0x39EE52A2,
  0x3AE2CB54,
  0x3B6487AF,
  0x3CFBF8B8,
  0x3D7DB443,
  0x3E712DB5,
  0x3FF7614E,
  0x4019A3D2,
  0x419FEF29,
  0x429376DF,
  0x43153A24,
  0x448A4533,
  0x450C09C8,
  0x4600903E,
  0x4786DCC5,
  0x48B822EB,
  0x493E6E10,
  0x4A32F7E6,
  0x4BB4BB1D,
  0x4C2BC40A,
  0x4DAD88F1,
  0x4EA11107,
  0x4F275DFC,
  0x50DCED5B,
  0x515AA1A0,
  0x52563856,
  0x53D074AD,
  0x544F0BBA,
  0x55C94741,
  0x56C5DEB7,
  0x5743924C,
  0x587D6C62,
  0x59FB2099,
  0x5AF7B96F,
  0x5B71F594,
  0x5CEE8A83,
  0x5D68C678,
  0x5E645F8E,
  0x5FE21375,
  0x6015723B,
  0x61933EC0,
  0x629FA736,
  0x6319EBCD,
  0x648694DA,
  0x6500D821,
  0x660C41D7,
  0x678A0D2C,
  0x68B4F302,
  0x6932BFF9,
  0x6A3E260F,
  0x6BB86AF4,
  0x6C2715E3,
  0x6DA15918,
  0x6EADC0EE,
  0x6F2B8C15,
  0x70D03CB2,
  0x71567049,
  0x725AE9BF,
  0x73DCA544,
  0x7443DA53,
  0x75C596A8,
  0x76C90F5E,
  0x774F43A5,
  0x7871BD8B,
  0x79F7F170,
  0x7AFB6886,
  0x7B7D247D,
  0x7CE25B6A,
  0x7D641791,
  0x7E688E67,
  0x7FEEC29C,
  0x803347A4,
  0x81B50B5F,
  0x82B992A9,
  0x833FDE52,
  0x84A0A145,
  0x8526EDBE,
  0x862A7448,
  0x87AC38B3,
  0x8892C69D,
  0x89148A66,
  0x8A181390,
  0x8B9E5F6B,
  0x8C01207C,
  0x8D876C87,
  0x8E8BF571,
  0x8F0DB98A,
  0x90F6092D,
  0x917045D6,
  0x927CDC20,
  0x93FA90DB,
  0x9465EFCC,
  0x95E3A337,
  0x96EF3AC1,
  0x9769763A,
  0x98578814,
  0x99D1C4EF,
  0x9ADD5D19,
  0x9B5B11E2,
  0x9CC46EF5,
  0x9D42220E,
  0x9E4EBBF8,
  0x9FC8F703,
  0xA03F964D,
  0xA1B9DAB6,
  0xA2B54340,
  0xA3330FBB,
  0xA4AC70AC,
  0xA52A3C57,
  0xA626A5A1,
  0xA7A0E95A,
  0xA89E1774,
  0xA9185B8F,
  0xAA14C279,
  0xAB928E82,
  0xAC0DF195,
  0xAD8BBD6E,
  0xAE872498,
  0xAF016863,
  0xB0FAD8C4,
  0xB17C943F,
  0xB2700DC9,
  0xB3F64132,
  0xB4693E25,
  0xB5EF72DE,
  0xB6E3EB28,
  0xB765A7D3,
  0xB85B59FD,
  0xB9DD1506,
  0xBAD18CF0,
  0xBB57C00B,
  0xBCC8BF1C,
  0xBD4EF3E7,
  0xBE426A11,
  0xBFC426EA,
  0xC02AE476,
  0xC1ACA88D,
  0xC2A0317B,
  0xC3267D80,
  0xC4B90297,
  0xC53F4E6C,
  0xC633D79A,
  0xC7B59B61,
  0xC88B654F,
  0xC90D29B4,
  0xCA01B042,
  0xCB87FCB9,
  0xCC1883AE,
  0xCD9ECF55,
  0xCE9256A3,
  0xCF141A58,
  0xD0EFAAFF,
  0xD169E604,
  0xD2657FF2,
  0xD3E33309,
  0xD47C4C1E,
  0xD5FA00E5,
  0xD6F69913,
  0xD770D5E8,
  0xD84E2BC6,
  0xD9C8673D,
  0xDAC4FECB,
  0xDB42B230,
  0xDCDDCD27,
  0xDD5B81DC,
  0xDE57182A,
  0xDFD154D1,
  0xE026359F,
  0xE1A07964,
  0xE2ACE092,
  0xE32AAC69,
  0xE4B5D37E,
  0xE5339F85,
  0xE63F0673,
  0xE7B94A88,
  0xE887B4A6,
  0xE901F85D,
  0xEA0D61AB,
  0xEB8B2D50,
  0xEC145247,
  0xED921EBC,
  0xEE9E874A,
  0xEF18CBB1,
  0xF0E37B16,
  0xF16537ED,
  0xF269AE1B,
  0xF3EFE2E0,
  0xF4709DF7,
  0xF5F6D10C,
  0xF6FA48FA,
  0xF77C0401,
  0xF842FA2F,
  0xF9C4B6D4,
  0xFAC82F22,
  0xFB4E63D9,
  0xFCD11CCE,
  0xFD575035,
  0xFE5BC9C3,
  0xFFDD8538,
]);

var hexDigits = Uint8List.fromList([
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, // 0-27
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5,
  6, 7, // 28..48(0).49(1)...55(7)
  8, 9, 0, 0, 0, 0, 0, 0, 0, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, // 56(8)...65(0xa)...70(0xf)...83
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0, 0, 0,
  0, 0, 0, 0, 0, 0, // 84...97(0xa)...102(0xf)...111
]);

Uint8List uint256SetHex(String hex) {
  var result = List<int>(32);
  for (int i = 0, j = hex.length - 1; i < 32; i++) {
    result[i] = hexDigits[hex.codeUnitAt(j)];
    j--;
    result[i] = result[i] | hexDigits[hex.codeUnitAt(j)] << 4;
    j--;
  }
  return Uint8List.fromList(result);
}

int crc24q(Uint8List list, int size) {
  int crc = 0;
  for (int i = 0; i < size; i++) {
    var x = list.elementAt(i);
    crc = (crc << 8) ^ crc24qTable[x ^ (0xFF & (crc >> 16))];
  }
  return crc & 0x00ffffff;
}

String base32Encode5Bytes(Uint8List list) {
  String result = "";
  result = result + alphabet[(list[0] >> 3) & 0x1F];
  result = result + alphabet[((list[0] << 2) & 0x1C) | ((list[1] >> 6) & 0x03)];
  result = result + alphabet[(list[1] >> 1) & 0x1F];
  result = result + alphabet[((list[1] << 4) & 0x10) | ((list[2] >> 4) & 0x0F)];
  result = result + alphabet[((list[2] << 1) & 0x1E) | ((list[3] >> 7) & 0x01)];
  result = result + alphabet[(list[3] >> 2) & 0x1F];
  result = result + alphabet[((list[3] << 3) & 0x18) | ((list[4] >> 5) & 0x07)];
  result = result + alphabet[(list[4] & 0x1F)];
  return result;
}

String base32Encode(Uint8List list) {
  var crc = crc24q(list, 32);
  var result = "";
  for (int i = 0; i < 30; i = i + 5) {
    result += base32Encode5Bytes(list.sublist(i, i + 5));
  }
  var tail =
      Uint8List.fromList([list[30], list[31], (crc >> 16), (crc >> 8), (crc)]);
  result += base32Encode5Bytes(tail);
  return result;
}

String publicKeyString(String hex) {
  var bytes = uint256SetHex(hex);
  return "1" + base32Encode(bytes);

}
Uint8List base32Decode5Bytes(String psz)
{
    var digit = Uint8List.fromList([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 
    8, 9, -1, -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 16, 17, -1, 18, 19,
     -1, 20, 21, -1, 22, 23, 24, 25, 26, -1, 27, 28, 29, 30, 31, -1, -1, -1, -1, -1, 
     -1, 10, 11, 12, 13, 14, 15, 16, 17, -1, 18, 19, -1, 20, 21, -1, 22, 23, 24, 25, 
     26, -1, 27, 28, 29, 30, 31, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
     -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ]);

  var idx = List<int>(8);
  idx[0] = digit[psz.codeUnitAt(0)];
	idx[1] = digit[psz.codeUnitAt(1)];
	idx[2] = digit[psz.codeUnitAt(2)];
	idx[3] = digit[psz.codeUnitAt(3)];
	idx[4] = digit[psz.codeUnitAt(4)];
	idx[5] = digit[psz.codeUnitAt(5)];
	idx[6] = digit[psz.codeUnitAt(6)];
	idx[7] = digit[psz.codeUnitAt(7)];
  var md5 = List<int>(5);
  md5[0] = ((idx[0] << 3) & 0xF8) | ((idx[1] >> 2) & 0x07);
  md5[1] = ((idx[1] << 6) & 0xC0) | ((idx[2] << 1) & 0x3E) | ((idx[3] >> 4) & 0x01);
  md5[2] = ((idx[3] << 4) & 0xF0) | ((idx[4] >> 1) & 0x0F);
  md5[3] = ((idx[4] << 7) & 0x80) | ((idx[5] << 2) & 0x7C) | ((idx[6] >> 3) & 0x03);
  md5[4] = ((idx[6] << 5) & 0xE0) | ((idx[7] & 0x1F));
  return Uint8List.fromList(md5);
}

Uint8List base32Decode(String strBase32)
{
    var data = List<int>(35);
    var temp = List<int>(5);
    var m=0;
    for (int i = 0; i < 7; i++)
    {
      temp = base32Decode5Bytes(strBase32.substring(i*8,8*(i+1)));
      for(int j=0;j<5;j++)
      {
        data[m++] = temp[j];
      }
    }
    return Uint8List.fromList(data).sublist(0,32);
}
