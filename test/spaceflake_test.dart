import 'dart:collection';
import 'dart:io';

import 'package:spaceflake/spaceflake.dart';
import 'package:test/test.dart';

void main() {
  test("Bulk generation should be unique", () {
    var spaceflakes = HashMap();
    var settings = BulkGeneratorSettings(1_000_000);
    var bulk = bulkGenerate(settings);
    for (var spaceflake in bulk) {
      if (spaceflakes.containsKey(spaceflake.toString())) {
        throw Exception("Spaceflake ID ${spaceflake.id} is a duplicate");
      }
      spaceflakes[spaceflake.toString()] = spaceflake;
    }
  });

  test("Bulk generation on node should be unique", () {
    var spaceflakes = HashMap();
    var node = Node(1);
    var bulk = node.bulkGenerate(1_000_000);
    for (var spaceflake in bulk) {
      if (spaceflakes.containsKey(spaceflake.toString())) {
        throw Exception("Spaceflake ID ${spaceflake.id} is a duplicate");
      }
      spaceflakes[spaceflake.toString()] = spaceflake;
    }
  });

  test("Bulk generation on worker should be unique", () {
    var spaceflakes = HashMap();
    var node = Node(1);
    var worker = node.newWorker();
    var bulk = worker.bulkGenerate(1_000_000);
    for (var spaceflake in bulk) {
      if (spaceflakes.containsKey(spaceflake.toString())) {
        throw Exception("Spaceflake ID ${spaceflake.id} is a duplicate");
      }
      spaceflakes[spaceflake.toString()] = spaceflake;
    }
  });

  test("generateAt should generate a Spaceflake for a given time", () {
    var node = Node(1);
    var worker = node.newWorker();
    var sf = worker.generateAt(1532180612064);
    expect(sf.time(), 1532180612064);
  });

  test("generateAt with a date in the future should throw an error", () {
    var node = Node(1);
    var worker = node.newWorker();
    expect(() => worker.generateAt(2662196938000), throwsException);
  });

  test("Generation on worker should yield unique Spaceflakes", () {
    var spaceflakes = HashMap();
    var node = Node(1);
    var worker = node.newWorker();

    for (final _ in Iterable.generate(1000)) {
      var spaceflake = worker.generate();
      if (spaceflakes.containsKey(spaceflake.toString())) {
        throw Exception("Spaceflake ID ${spaceflake.id} is a duplicate");
      }
      spaceflakes[spaceflake.toString()] = spaceflake;
    }
  });

  test("Generation should yield unique Spaceflakes", () {
    var spaceflakes = HashMap();
    var settings = GeneratorSettings(0, 0);

    for (final _ in Iterable.generate(1000)) {
      var spaceflake = generate(settings);
      if (spaceflakes.containsKey(spaceflake.toString())) {
        throw Exception("Spaceflake ID ${spaceflake.id} is a duplicate");
      }
      spaceflakes[spaceflake.toString()] = spaceflake;
      // When using random there is a chance that the sequence will be twice the same due to Dart's speed, hence using a worker is better. We wait a millisecond to make sure it's different.
      sleep(Duration(milliseconds: 1));
    }
  });
}
