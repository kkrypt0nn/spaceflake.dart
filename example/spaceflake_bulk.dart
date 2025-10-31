import 'package:spaceflake/spaceflake.dart';

void main() {
  var settings = BulkGeneratorSettings(2_000_000);
  try {
    var spaceflakes = bulkGenerate(settings);
    print("Successfully generated ${spaceflakes.length} Spaceflakes");
    print(spaceflakes.elementAt(1337331).decompose());
  } catch (e) {
    print("Error: $e");
  }

  var nodeOne = Node(1);
  try {
    var spaceflakes = nodeOne.bulkGenerate(1_000_000);
    print("Successfully generated ${spaceflakes.length} Spaceflakes");
    print(spaceflakes.elementAt(7331).decompose());
  } catch (e) {
    print("Error: $e");
  }

  var nodeTwo = Node(2);
  var worker = nodeTwo.newWorker();
  try {
    var spaceflakes = worker.bulkGenerate(500_000);
    print("Successfully generated ${spaceflakes.length} Spaceflakes");
    print(spaceflakes.elementAt(1337).decompose());
  } catch (e) {
    print("Error: $e");
  }
}
