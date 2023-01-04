// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hashlib/src/core/hash_algo.dart';
import 'package:hashlib/src/core/hash_digest.dart';
import 'package:hashlib/src/core/utils.dart';

/// Generates a 128-bit MD5 hash digest from the input.
HashDigest md5buffer(final Iterable<int> input) {
  final md5 = MD5();
  md5.update(input);
  return md5.digest();
}

/// Generates a 128-bit MD5 hash as hexadecimal digest from string
HashDigest md5(final String input, [Encoding? encoding]) {
  return md5buffer(toBytes(input, encoding));
}

/// Generates a 128-bit MD5 hash digest from stream
Future<HashDigest> md5stream(final Stream<List<int>> inputStream) async {
  final md5 = MD5();
  await inputStream.forEach(md5.update);
  return md5.digest();
}

const int _mask32 = 0xFFFFFFFF;

/// This implementation is derived from the RSA Data Security, Inc.
/// [MD5 Message-Digest Algorithm][rfc1321].
///
/// [rfc1321]: https://datatracker.ietf.org/doc/html/rfc1321
///
/// **Warning**: MD5 has extensive vulnerabilities. It can be safely used
/// for checksum, but do not use it for cryptographic purposes.
class MD5 extends HashAlgo {
  final _chunk = Uint32List(16); /* 512-bit message block */

  /// Initializes a new instance of MD5 message-digest.
  MD5()
      : super(
          hashSize: 128,
          blockSize: 512,
          endian: Endian.little,
          seed: [
            0x67452301, // a
            0xefcdab89, // b
            0x98badcfe, // c
            0x10325476, // d
          ],
        );

  /// Rotates x left by n bits.
  int _rotl(int x, int n) =>
      ((x << n) & _mask32) | ((x & _mask32) >>> (32 - n));

  /// Basic MD5 function for round 1.
  int _tF(int x, int y, int z) => (x & y) | (~x & z);

  /// Basic MD5 function for round 2.
  int _tG(int x, int y, int z) => (x & z) | (y & ~z);

  /// Basic MD5 function for round 3.
  int _tH(int x, int y, int z) => x ^ y ^ z;

  /// Basic MD5 function for round 4.
  int _tI(int x, int y, int z) => y ^ (x | (~z & _mask32));

  /// MD5 Transformation for round 1.
  int _tFF(int a, int b, int c, int d, int x, int s, int ac) =>
      (b + _rotl(a + _tF(b, c, d) + x + ac, s)) & _mask32;

  /// MD5 Transformation for round 2.
  int _tGG(int a, int b, int c, int d, int x, int s, int ac) =>
      (b + _rotl(a + _tG(b, c, d) + x + ac, s)) & _mask32;

  /// MD5 Transformation for round 3.
  int _tHH(int a, int b, int c, int d, int x, int s, int ac) =>
      (b + _rotl(a + _tH(b, c, d) + x + ac, s)) & _mask32;

  /// MD5 Transformation for round 4.
  int _rII(int a, int b, int c, int d, int x, int s, int ac) =>
      (b + _rotl(a + _tI(b, c, d) + x + ac, s)) & _mask32;

  @override
  void $process(final Uint32List state, final Uint8List buffer) {
    $decode(buffer, _chunk);
    final x = _chunk;

    // Shift amounts for round 1.
    const int s11 = 07;
    const int s12 = 12;
    const int s13 = 17;
    const int s14 = 22;

    // Shift amounts for round 2.
    const int s21 = 05;
    const int s22 = 09;
    const int s23 = 14;
    const int s24 = 20;

    // Shift amounts for round 3.
    const int s31 = 04;
    const int s32 = 11;
    const int s33 = 16;
    const int s34 = 23;

    // Shift amounts for round 4.
    const int s41 = 06;
    const int s42 = 10;
    const int s43 = 15;
    const int s44 = 21;

    int a = state[0];
    int b = state[1];
    int c = state[2];
    int d = state[3];

    // Formula for the last param: floor(2^32 * abs(sin(i + 1)))
    /* Round 1 */
    a = _tFF(a, b, c, d, x[0], s11, 0xd76aa478); /* 1 */
    d = _tFF(d, a, b, c, x[1], s12, 0xe8c7b756); /* 2 */
    c = _tFF(c, d, a, b, x[2], s13, 0x242070db); /* 3 */
    b = _tFF(b, c, d, a, x[3], s14, 0xc1bdceee); /* 4 */
    a = _tFF(a, b, c, d, x[4], s11, 0xf57c0faf); /* 5 */
    d = _tFF(d, a, b, c, x[5], s12, 0x4787c62a); /* 6 */
    c = _tFF(c, d, a, b, x[6], s13, 0xa8304613); /* 7 */
    b = _tFF(b, c, d, a, x[7], s14, 0xfd469501); /* 8 */
    a = _tFF(a, b, c, d, x[8], s11, 0x698098d8); /* 9 */
    d = _tFF(d, a, b, c, x[9], s12, 0x8b44f7af); /* 10 */
    c = _tFF(c, d, a, b, x[10], s13, 0xffff5bb1); /* 11 */
    b = _tFF(b, c, d, a, x[11], s14, 0x895cd7be); /* 12 */
    a = _tFF(a, b, c, d, x[12], s11, 0x6b901122); /* 13 */
    d = _tFF(d, a, b, c, x[13], s12, 0xfd987193); /* 14 */
    c = _tFF(c, d, a, b, x[14], s13, 0xa679438e); /* 15 */
    b = _tFF(b, c, d, a, x[15], s14, 0x49b40821); /* 16 */

    /* Round 2 */
    a = _tGG(a, b, c, d, x[1], s21, 0xf61e2562); /* 17 */
    d = _tGG(d, a, b, c, x[6], s22, 0xc040b340); /* 18 */
    c = _tGG(c, d, a, b, x[11], s23, 0x265e5a51); /* 19 */
    b = _tGG(b, c, d, a, x[0], s24, 0xe9b6c7aa); /* 20 */
    a = _tGG(a, b, c, d, x[5], s21, 0xd62f105d); /* 21 */
    d = _tGG(d, a, b, c, x[10], s22, 0x2441453); /* 22 */
    c = _tGG(c, d, a, b, x[15], s23, 0xd8a1e681); /* 23 */
    b = _tGG(b, c, d, a, x[4], s24, 0xe7d3fbc8); /* 24 */
    a = _tGG(a, b, c, d, x[9], s21, 0x21e1cde6); /* 25 */
    d = _tGG(d, a, b, c, x[14], s22, 0xc33707d6); /* 26 */
    c = _tGG(c, d, a, b, x[3], s23, 0xf4d50d87); /* 27 */
    b = _tGG(b, c, d, a, x[8], s24, 0x455a14ed); /* 28 */
    a = _tGG(a, b, c, d, x[13], s21, 0xa9e3e905); /* 29 */
    d = _tGG(d, a, b, c, x[2], s22, 0xfcefa3f8); /* 30 */
    c = _tGG(c, d, a, b, x[7], s23, 0x676f02d9); /* 31 */
    b = _tGG(b, c, d, a, x[12], s24, 0x8d2a4c8a); /* 32 */

    /* Round 3 */
    a = _tHH(a, b, c, d, x[5], s31, 0xfffa3942); /* 33 */
    d = _tHH(d, a, b, c, x[8], s32, 0x8771f681); /* 34 */
    c = _tHH(c, d, a, b, x[11], s33, 0x6d9d6122); /* 35 */
    b = _tHH(b, c, d, a, x[14], s34, 0xfde5380c); /* 36 */
    a = _tHH(a, b, c, d, x[1], s31, 0xa4beea44); /* 37 */
    d = _tHH(d, a, b, c, x[4], s32, 0x4bdecfa9); /* 38 */
    c = _tHH(c, d, a, b, x[7], s33, 0xf6bb4b60); /* 39 */
    b = _tHH(b, c, d, a, x[10], s34, 0xbebfbc70); /* 40 */
    a = _tHH(a, b, c, d, x[13], s31, 0x289b7ec6); /* 41 */
    d = _tHH(d, a, b, c, x[0], s32, 0xeaa127fa); /* 42 */
    c = _tHH(c, d, a, b, x[3], s33, 0xd4ef3085); /* 43 */
    b = _tHH(b, c, d, a, x[6], s34, 0x4881d05); /* 44 */
    a = _tHH(a, b, c, d, x[9], s31, 0xd9d4d039); /* 45 */
    d = _tHH(d, a, b, c, x[12], s32, 0xe6db99e5); /* 46 */
    c = _tHH(c, d, a, b, x[15], s33, 0x1fa27cf8); /* 47 */
    b = _tHH(b, c, d, a, x[2], s34, 0xc4ac5665); /* 48 */

    /* Round 4 */
    a = _rII(a, b, c, d, x[0], s41, 0xf4292244); /* 49 */
    d = _rII(d, a, b, c, x[7], s42, 0x432aff97); /* 50 */
    c = _rII(c, d, a, b, x[14], s43, 0xab9423a7); /* 51 */
    b = _rII(b, c, d, a, x[5], s44, 0xfc93a039); /* 52 */
    a = _rII(a, b, c, d, x[12], s41, 0x655b59c3); /* 53 */
    d = _rII(d, a, b, c, x[3], s42, 0x8f0ccc92); /* 54 */
    c = _rII(c, d, a, b, x[10], s43, 0xffeff47d); /* 55 */
    b = _rII(b, c, d, a, x[1], s44, 0x85845dd1); /* 56 */
    a = _rII(a, b, c, d, x[8], s41, 0x6fa87e4f); /* 57 */
    d = _rII(d, a, b, c, x[15], s42, 0xfe2ce6e0); /* 58 */
    c = _rII(c, d, a, b, x[6], s43, 0xa3014314); /* 59 */
    b = _rII(b, c, d, a, x[13], s44, 0x4e0811a1); /* 60 */
    a = _rII(a, b, c, d, x[4], s41, 0xf7537e82); /* 61 */
    d = _rII(d, a, b, c, x[11], s42, 0xbd3af235); /* 62 */
    c = _rII(c, d, a, b, x[2], s43, 0x2ad7d2bb); /* 63 */
    b = _rII(b, c, d, a, x[9], s44, 0xeb86d391); /* 64 */

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
  }

  @override
  void $finalize(final Uint32List state, final Uint8List buffer, int pos) {
    // Adding a single 1 bit padding
    buffer[pos++] = 0x80;

    // If buffer length > 56 bytes, skip this block
    if (pos > 56) {
      while (pos < 64) {
        buffer[pos++] = 0;
      }
      $process(state, buffer);
      pos = 0;
    }

    // Padding with 0s until buffer length is 56 bytes
    while (pos < 56) {
      buffer[pos++] = 0;
    }

    // Append original message length in bits to message
    $encode64(Uint64List.fromList([messageLengthInBits]), buffer, pos);
    $process(state, buffer);
  }
}
