import 'package:spaceflake/spaceflake.dart';

void main() {
  var node = Node(1);
  var worker = node.newWorker();
  try {
    var sf = worker.generate();
    print("Generated Spaceflake: ${sf.decompose()}");
  } catch (e) {
    print("Error: $e");
  }
}
