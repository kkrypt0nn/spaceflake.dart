import 'package:spaceflake/spaceflake.dart';

void main() {
  var settings = GeneratorSettings(0, 0);
  settings.baseEpoch = 1640995200000;
  try {
    var sf = generate(settings);
    print("Generated Spaceflake: ${sf.decompose()}");
  } catch (e) {
    print("Error: $e");
  }

  settings.nodeId = 5;
  settings.workerId = 5;
  settings.sequence = 1337;
  try {
    var sf = generate(settings);
    print("Generated Spaceflake: ${sf.decompose()}");
  } catch (e) {
    print("Error: $e");
  }
}
