// Copyright (c) 2021, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.

import 'dart:math';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart' as hashlib;
import 'package:sha3/sha3.dart' as sha3;
import 'package:pointycastle/digests/sha3.dart' as pc;

import 'base.dart';

Random random = Random();

class HashlibBenchmark extends Benchmark {
  HashlibBenchmark(int size, int iter) : super('hashlib', size, iter);

  @override
  void run() {
    hashlib.sha256.convert(input).bytes;
  }
}

class Sha3Benchmark extends Benchmark {
  Sha3Benchmark(int size, int iter) : super('sha3', size, iter);

  @override
  void run() {
    sha3.SHA3(256, sha3.SHA3_PADDING, 256)
      ..update(input)
      ..digest();
  }
}

class PointyCastleBenchmark extends Benchmark {
  Uint8List _input = Uint8List(0);
  PointyCastleBenchmark(int size, int iter) : super('PointyCastle', size, iter);

  @override
  void setup() {
    super.setup();
    _input = Uint8List.fromList(input);
  }

  @override
  void run() {
    final d = pc.SHA3Digest(256);
    d.process(_input);
  }
}

void main() {
  print('--------- SHA3-256 ----------');
  HashlibBenchmark(17, 1000).showDiff([
    Sha3Benchmark(17, 1000),
    PointyCastleBenchmark(17, 1000),
  ]);
  print('');
  HashlibBenchmark(1777, 50).showDiff([
    Sha3Benchmark(1777, 50),
    PointyCastleBenchmark(7000, 100),
  ]);
  print('');
  HashlibBenchmark(111000, 1).showDiff([
    Sha3Benchmark(111000, 1),
    PointyCastleBenchmark(777000, 1),
  ]);
  print('');
}
