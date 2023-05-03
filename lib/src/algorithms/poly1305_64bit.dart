// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

import 'dart:typed_data';

import 'package:hashlib/src/core/block_hash.dart';
import 'package:hashlib/src/core/mac_base.dart';

const int _mask32 = 0xFFFFFFFF;
const int _mask26 = 0x03FFFFFF;

/// This implementation is derived from the [The Poly1305 Algorithms] described
/// in the [ChaCha20 and Poly1305 for IETF Protocols][rfc] document.
///
/// The Reference implementation used for optimization:
/// https://github.com/floodyberry/poly1305-opt
///
/// [rfc]: https://www.ietf.org/rfc/rfc8439.html
class Poly1305Sink extends BlockHashSink with MACSinkBase {
  bool _initialized = false;
  // secret key: r
  int _r0 = 0;
  int _r1 = 0;
  int _r2 = 0;
  int _r3 = 0;
  int _r4 = 0;
  // authentication key: s
  int _s0 = 0;
  int _s1 = 0;
  int _s2 = 0;
  int _s3 = 0;
  // accumulator: a
  int _a0 = 0;
  int _a1 = 0;
  int _a2 = 0;
  int _a3 = 0;
  int _a4 = 0;
  // g = 5 * r
  int _g1 = 0;
  int _g2 = 0;
  int _g3 = 0;
  int _g4 = 0;

  @override
  final int hashLength = 16;

  /// Creates a new instance to process 16-bytes blocks with 17-bytes buffer
  Poly1305Sink() : super(16, bufferLength: 17);

  @override
  void reset() {
    super.reset();
    _a0 = 0;
    _a1 = 0;
    _a2 = 0;
    _a3 = 0;
    _a4 = 0;
  }

  /// Initialize the Poly1305 with the secret and the authentication
  ///
  /// Parameters:
  /// - [key] : The secret key `r` - a little-endian 16-byte integer
  /// - [secret] : The authentication key `s` - a little-endian 16-byte integer
  @override
  void init(List<int> key, [List<int>? secret]) {
    if (key.length != blockLength) {
      throw StateError('The key length must be 16 bytes');
    }
    if (secret != null && secret.length != 16) {
      throw StateError('The secret length must be 16 bytes');
    }

    // r = key[15..0]
    var key8 = key is Uint8List ? key : Uint8List.fromList(key);
    var kdata = key8.buffer.asByteData();
    _r0 = kdata.getUint32(0, Endian.little);
    _r1 = kdata.getUint32(3, Endian.little) >>> 2;
    _r2 = kdata.getUint32(6, Endian.little) >>> 4;
    _r3 = kdata.getUint32(9, Endian.little) >>> 6;
    _r4 = kdata.getUint32(12, Endian.little) >>> 8;

    // clamp(r): r &= 0x0ffffffc0ffffffc0ffffffc0fffffff
    _r0 &= 0x03ffffff;
    _r1 &= 0x03ffff03;
    _r2 &= 0x03ffc0ff;
    _r3 &= 0x03f03fff;
    _r4 &= 0x000fffff;

    _g1 = 5 * _r1;
    _g2 = 5 * _r2;
    _g3 = 5 * _r3;
    _g4 = 5 * _r4;

    if (secret != null) {
      // s = secret[15..0]
      var secret8 = secret is Uint8List ? secret : Uint8List.fromList(secret);
      var secret32 = secret8.buffer.asUint32List();
      _s0 = secret32[0];
      _s1 = secret32[1];
      _s2 = secret32[2];
      _s3 = secret32[3];
    }

    reset();
    _initialized = true;
  }

  @override
  void $process(List<int> chunk, int start, int end) {
    if (!_initialized) {
      throw StateError('The MAC instance is not initialized');
    }
    buffer[16] = 1;
    for (; start < end; start++, pos++) {
      if (pos == blockLength) {
        $update();
        pos = 0;
      }
      buffer[pos] = chunk[start];
    }
    if (pos == blockLength) {
      $update();
      pos = 0;
    }
  }

  @override
  void $update([List<int>? block, int offset = 0, bool last = false]) {
    int d0, d1, d2, d3, d4;

    // a += n
    _a0 += bdata.getUint32(0, Endian.little) & _mask26;
    _a1 += (bdata.getUint32(3, Endian.little) >>> 2) & _mask26;
    _a2 += (bdata.getUint32(6, Endian.little) >>> 4) & _mask26;
    _a3 += (bdata.getUint32(9, Endian.little) >>> 6) & _mask26;
    _a4 += (bdata.getUint32(12, Endian.little) >>> 8) & _mask26;
    _a4 += buffer[16] << 24;

    // a *= r
    d0 = _a0 * _r0 + _a1 * _g4 + _a2 * _g3 + _a3 * _g2 + _a4 * _g1;
    d1 = _a0 * _r1 + _a1 * _r0 + _a2 * _g4 + _a3 * _g3 + _a4 * _g2;
    d2 = _a0 * _r2 + _a1 * _r1 + _a2 * _r0 + _a3 * _g4 + _a4 * _g3;
    d3 = _a0 * _r3 + _a1 * _r2 + _a2 * _r1 + _a3 * _r0 + _a4 * _g4;
    d4 = _a0 * _r4 + _a1 * _r3 + _a2 * _r2 + _a3 * _r1 + _a4 * _r0;

    // a %= 2^130 - 5;
    d1 += d0 >>> 26;
    d2 += d1 >>> 26;
    d3 += d2 >>> 26;
    d4 += d3 >>> 26;
    _a0 = d0 & _mask26;
    _a1 = d1 & _mask26;
    _a2 = d2 & _mask26;
    _a3 = d3 & _mask26;
    _a4 = d4 & _mask26;
    _a0 += 5 * (d4 >>> 26);
    _a1 += _a0 >>> 26;
    _a0 &= _mask26;
  }

  @override
  Uint8List $finalize() {
    if (!_initialized) {
      throw StateError('The MAC instance is not initialized');
    }

    if (pos > 0) {
      buffer[pos] = 1;
      for (pos++; pos <= 16; pos++) {
        buffer[pos] = 0;
      }
      $update();
    }

    int d0, d1, d2, d3, d4;

    // fully carry
    _a1 += _a0 >>> 26;
    _a2 += _a1 >>> 26;
    _a3 += _a2 >>> 26;
    _a4 += _a3 >>> 26;
    _a0 &= _mask26;
    _a1 &= _mask26;
    _a2 &= _mask26;
    _a3 &= _mask26;

    // compute d = a - p
    d0 = _a0 + 5;
    d1 = _a1 + (d0 >>> 26);
    d2 = _a2 + (d1 >>> 26);
    d3 = _a3 + (d2 >>> 26);
    d4 = _a4 + (d3 >>> 26) - (1 << 26);
    d4 &= _mask32;

    // if a < p, take a; else, take d
    if ((d4 >>> 31) != 1) {
      _a0 = d0 & _mask26;
      _a1 = d1 & _mask26;
      _a2 = d2 & _mask26;
      _a3 = d3 & _mask26;
      _a4 = d4 & _mask26;
    }

    // modulus 2^128
    _a0 = ((_a0) | (_a1 << 26)) & _mask32;
    _a1 = ((_a1 >>> 6) | (_a2 << 20)) & _mask32;
    _a2 = ((_a2 >>> 12) | (_a3 << 14)) & _mask32;
    _a3 = ((_a3 >>> 18) | (_a4 << 8)) & _mask32;

    // a += s
    _a0 += _s0;
    _a1 += _s1 + (_a0 >>> 32);
    _a2 += _s2 + (_a1 >>> 32);
    _a3 += _s3 + (_a2 >>> 32);

    return Uint32List.fromList([
      _a0,
      _a1,
      _a2,
      _a3,
    ]).buffer.asUint8List();
  }
}
