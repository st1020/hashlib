// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

import 'keccak_64bit.dart' if (dart.library.js) 'keccak_32bit.dart';

class Shake128Hash extends KeccakHash {
  /// Create a SHAKE-128 hash generator with arbitrary output size.
  ///
  /// If [outputLengthInBytes] is 0, it will generate an infinite sequence of
  /// numbers with generate(), but the digest() will return an empty string.
  ///
  /// If [outputLengthInBytes] is null, 128-bit output is generated by default.
  Shake128Hash([int? outputLengthInBytes])
      : super(
          stateSize: 128 >>> 3,
          paddingByte: 0x1f,
          outputSize: outputLengthInBytes,
        );
}

class Shake256Hash extends KeccakHash {
  /// Create a SHAKE-256 hash generator with arbitrary output size.
  ///
  /// If [outputLengthInBytes] is 0, it will generate an infinite sequence of
  /// numbers with generate(), but the digest() will return an empty string.
  ///
  /// If [outputLengthInBytes] is null, 256-bit output is generated by default.
  Shake256Hash([int? outputLengthInBytes])
      : super(
          stateSize: 256 >>> 3,
          paddingByte: 0x1f,
          outputSize: outputLengthInBytes,
        );
}
