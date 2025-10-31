import 'dart:collection';
import 'dart:io';
import 'dart:math';

/// The default epoch used **with milliseconds**, which is the 1st of January 2015 at 12:00:00 AM GMT.
const int epoch = 1420070400000;

/// The maximum number that can be set with 5 bits.
const int _max5Bits = 31;

/// The maximum number that can be set with 12 bits.
const int _max12Bits = 4095;

/// The maximum amount of milliseconds for clock drift tolerance.
const int _clockDriftToleranceMs = 10;

/// A Spaceflake is the internal name for a Snowflake ID.
///
/// Apart from being a crystal of snow, a snowflake is a form of unique identifier which is being used in distributed computing. It has specific parts and is 64 bits long in binary.
/// ![A Spaceflake structure](https://raw.githubusercontent.com/kkrypt0nn/spaceflake.dart/main/assets/spaceflake_structure.png)
class Spaceflake {
  /// The decimal representation of the Spaceflake.
  int id = 0;

  /// The  base epoch that was used to generate the Spaceflake, default is [`EPOCH`].
  final int _baseEpoch;

  /// The default implementation of a Spaceflake.
  Spaceflake(this.id, this._baseEpoch);

  /// The toString implementation of a Spaceflake. Will just return its ID.
  @override
  String toString() {
    return id.toString();
  }

  /// Returns the time at which the Spaceflake has been generated.
  int time() {
    return (id >> 22) + _baseEpoch;
  }

  /// Returns the node ID of the Spaceflake.
  int nodeId() {
    return (id & 0x3E0000) >> 17;
  }

  /// Returns the worker ID of the Spaceflake.
  int workerId() {
    return (id & 0x1F000) >> 12;
  }

  /// Returns the sequence of the Spaceflake.
  int sequence() {
    return id & 0xFFF;
  }

  /// Returns the ID of the Spaceflake as a string.
  String stringId() {
    return id.toString();
  }

  /// Returns the ID in binary of the Spaceflake as a string.
  String toBinary() {
    return "0".padLeft(64, id.toRadixString(2));
  }

  /// Returns a hashmap of key-values with each part of the Spaceflake.
  HashMap<String, int> decompose() {
    return HashMap.from({
      "id": id,
      "nodeId": nodeId(),
      "sequence": sequence(),
      "time": time(),
      "workerId": workerId(),
    });
  }

  /// Returns a hashmap of key-values with each part of the Spaceflake as binary.
  HashMap<String, int> decomposeBinary() {
    return HashMap.from({
      "id": "0".padLeft(64, id.toRadixString(2)),
      "nodeId": "0".padLeft(5, nodeId().toRadixString(2)),
      "sequence": "0".padLeft(12, sequence().toRadixString(2)),
      "time": "0".padLeft(41, time().toRadixString(2)),
      "workerId": "0".padLeft(5, workerId().toRadixString(2)),
    });
  }
}

/// A node holds multiple [Worker] structures and has a, ideally, unique ID given.
class Node {
  /// The ID of the node, ideally it should be unique and not be used multiple times within an application.
  int id = 1;

  /// The list of workers the node holds, which will then be responsible to generate the Spaceflakes.
  final List<Worker> _workers = List.empty(growable: true);

  /// Create a new node for the given ID.
  factory Node(int id) {
    if (id > _max5Bits) {
      throw Exception("Node ID must be less than $_max5Bits");
    }

    return Node._internal(id);
  }
  Node._internal(this.id);

  /// Create a new worker and push it to the list of workers of the node to generate Spaceflakes.
  Worker newWorker() {
    var worker = Worker(_workers.length + 1, id);
    _workers.add(worker);
    return worker;
  }

  /// Remove a worker given its ID from the list of workers.
  void removeWorker(int index) {
    _workers.removeAt(index);
  }

  /// Returns the list of workers the node is currently holding.
  List<Worker> getWorkers() {
    return _workers;
  }

  /// Generate an amount of Spaceflakes on the node.
  ///
  /// The workers will automatically scale, so there is no need to add new workers to the node.
  List<Spaceflake> bulkGenerate(int amount) {
    var node = Node(id);
    var worker = node.newWorker();
    var spaceflakes = List<Spaceflake>.empty(growable: true);

    for (var i = 1; i <= amount; i++) {
      if (i % ((_max12Bits * _max5Bits) + 1) == 0) {
        sleep(Duration(milliseconds: 1));
        node._workers.clear();
        worker = node.newWorker();
      } else if (i % _max12Bits == 0 && i % (_max12Bits * _max5Bits) != 0) {
        worker = node.newWorker();
      }

      spaceflakes.add(_generateOnNodeAndWorker(node.id, worker));
    }

    return spaceflakes;
  }
}

/// A worker is the structure that is responsible to generate the Spaceflake.
class Worker {
  /// The ID of the worker, ideally it should be unique and not be used multiple times within an application.
  int id = 0;

  /// The base epoch that will be used to generate the Spaceflakes, default is [epoch].
  int baseEpoch = epoch;

  /// The node ID to which the worker belongs to.
  int nodeId = 0;

  /// The sequence of the worker, which is usually an incremented number but can be anything.
  ///
  /// If set to 0, it will be the incremented number.
  int sequence = 0;

  /// The incremented number of the worker, used for the sequence.
  int increment = 0;

  /// The timestamp of the most recently generated Spaceflake, used to prevent clock drifting.
  int lastTimestamp = 0;

  factory Worker(int id, int nodeId) {
    if (id > _max12Bits) {
      throw Exception("Worker ID must be less than $_max12Bits");
    }

    return Worker._internal(id, nodeId);
  }
  Worker._internal(this.id, this.nodeId);

  /// Generate a new Spaceflake on this worker.
  Spaceflake generate() {
    return _generateOnNodeAndWorker(nodeId, this);
  }

  /// Generate a new Spaceflake on this worker at a specific time.
  Spaceflake generateAt(int at) {
    return _generateOnNodeAndWorker(nodeId, this, at: at);
  }

  /// Generate an amount of Spaceflakes on the worker.
  ///
  /// It will automatically sleep of a millisecond, only if needed, to prevent duplicated Spaceflakes to get generated.
  List<Spaceflake> bulkGenerate(int amount) {
    var spaceflakes = List<Spaceflake>.empty(growable: true);

    for (var i = 1; i <= amount; i++) {
      if (i % (_max12Bits + 1) == 0) {
        sleep(Duration(milliseconds: 1));
      }
      spaceflakes.add(_generateOnNodeAndWorker(nodeId, this));
    }

    return spaceflakes;
  }
}

/// Settings to bulk generate Spaceflakes easily.
class BulkGeneratorSettings {
  /// The base epoch that will be used to generate the Spaceflakes, default is [epoch].
  int baseEpoch = epoch;

  /// The amount of Spaceflakes to generate.
  final int _amount;

  BulkGeneratorSettings(this._amount);
}

/// Generate an amount of Spaceflakes for the given settings.
///
/// Nodes and workers will be automatically scaled, and the function will also sleep of a millisecond if needed.
List<Spaceflake> bulkGenerate(BulkGeneratorSettings settings) {
  var node = Node(1);
  var worker = node.newWorker();
  worker.baseEpoch = settings.baseEpoch;
  var spaceflakes = List<Spaceflake>.empty(growable: true);

  for (var i = 1; i <= settings._amount; i++) {
    if (i % (_max12Bits * _max5Bits * _max5Bits) == 0) {
      sleep(Duration(milliseconds: 1));
      var newNode = Node(1);
      var newWorker = newNode.newWorker();
      newWorker.baseEpoch = settings.baseEpoch;
      node = newNode;
      worker = newWorker;
    } else if (node._workers.length % _max5Bits == 0 &&
        i % (_max5Bits * _max12Bits) == 0) {
      var newNode = Node(1);
      var newWorker = newNode.newWorker();
      newWorker.baseEpoch = settings.baseEpoch;
      node = newNode;
      worker = newWorker;
    } else if (i % _max12Bits == 0) {
      var newWorker = node.newWorker();
      newWorker.baseEpoch = settings.baseEpoch;
      worker = newWorker;
    }

    spaceflakes.add(_generateOnNodeAndWorker(node.id, worker));
  }

  return spaceflakes;
}

/// Settings to generate Spaceflakes normally.
class GeneratorSettings {
  /// The base epoch that will be used to generate the Spaceflakes, default is [epoch].
  int baseEpoch = epoch;

  /// The node ID for which the Spaceflake will be generated.
  int nodeId = 0;

  // The worker ID for which the Spaceflake will be generated.
  int workerId = 1;

  /// The sequence of the generated Spaceflake.
  int sequence = 0;

  factory GeneratorSettings(int nodeId, int workerId) {
    if (nodeId > _max5Bits) {
      throw Exception("Node ID must be less than $_max5Bits");
    }
    if (workerId > _max12Bits) {
      throw Exception("Worker ID must be less than $_max12Bits");
    }

    return GeneratorSettings._internal(nodeId, workerId);
  }
  GeneratorSettings._internal(this.nodeId, this.workerId);
}

/// Generate a Spaceflake for the given settings.
///
/// If the sequence is set to `0`, which is default, it it will get randomly generated.
Spaceflake generate(GeneratorSettings settings) {
  var worker = Worker(settings.workerId, settings.nodeId);
  worker.sequence = (settings.sequence == 0)
      ? Random().nextInt(_max12Bits) + 1
      : settings.sequence;
  return _generateOnNodeAndWorker(settings.nodeId, worker);
}

/// Generate a Spaceflake for the given settings at a specific time.
///
/// If the sequence is set to `0`, which is default, it it will get randomly generated.
Spaceflake generateAt(GeneratorSettings settings, int at) {
  var worker = Worker(settings.workerId, settings.nodeId);
  worker.sequence = (settings.sequence == 0)
      ? Random().nextInt(_max12Bits) + 1
      : settings.sequence;
  return _generateOnNodeAndWorker(settings.nodeId, worker, at: at);
}

/// Parse the time of a Spaceflake ID.
int parseTime(int spaceflakeId, int baseEpoch) {
  return (spaceflakeId >> 22) + baseEpoch;
}

/// Parse the node ID of a Spaceflake ID.
int parseNodeId(int spaceflakeId) {
  return (spaceflakeId & 0x3E0000) >> 17;
}

/// Parse the worker ID of a Spaceflake ID.
int parseWorkerId(int spaceflakeId) {
  return (spaceflakeId & 0x1F000) >> 12;
}

/// Parse the sequence of a Spaceflake ID.
int parseSequence(int spaceflakeId) {
  return spaceflakeId & 0xFFF;
}

/// Decompose a Spaceflake ID, and get a key-value hashmap with each part of a Spaceflake.
HashMap<String, int> decompose(int spaceflakeId, int baseEpoch) {
  return Spaceflake(spaceflakeId, baseEpoch).decompose();
}

/// Decompose a Spaceflake ID, and get a key-value hashmap with each part of a Spaceflake in binary.
HashMap<String, int> decomposeBinary(int spaceflakeId, int baseEpoch) {
  return Spaceflake(spaceflakeId, baseEpoch).decomposeBinary();
}

Spaceflake _generateOnNodeAndWorker(int nodeId, Worker worker, {int at = -1}) {
  var now = DateTime.now().millisecondsSinceEpoch;
  var generateAt = (at == -1) ? now : at;

  if (nodeId > _max5Bits) {
    throw Exception("Node ID must be less than $_max5Bits");
  }
  if (worker.id > _max12Bits) {
    throw Exception("Worker ID must be less than $_max12Bits");
  }
  if (worker.baseEpoch > generateAt) {
    throw Exception(
      "Base epoch must be less than the time you want to generate the Spaceflake at",
    );
  }
  if (generateAt > now) {
    throw Exception(
      "The current time must be greater than the time you want to generate the Spaceflake at",
    );
  }

  var milliseconds = generateAt - worker.baseEpoch;

  if (milliseconds < worker.lastTimestamp) {
    var delta = worker.lastTimestamp - milliseconds;
    if (delta > _clockDriftToleranceMs) {
      throw Exception("Clock moved backwards by ${delta}ms");
    }
    sleep(Duration(milliseconds: delta + 1));
    milliseconds = DateTime.now().millisecondsSinceEpoch - worker.baseEpoch;
  }

  if (milliseconds == worker.lastTimestamp) {
    worker.increment += 1;
    if (worker.increment >= _max12Bits) {
      sleep(Duration(milliseconds: 1));
      milliseconds = DateTime.now().millisecondsSinceEpoch - worker.baseEpoch;
      worker.increment = 0;
    }
  } else {
    worker.increment = 0;
  }
  worker.lastTimestamp = milliseconds;

  int sequence = worker.sequence == 0 ? worker.increment : worker.sequence;
  int id =
      (milliseconds << 22) |
      (nodeId << 17) |
      (worker.id << 12) |
      (sequence & 0xFFF);

  return Spaceflake(id, worker.baseEpoch);
}
