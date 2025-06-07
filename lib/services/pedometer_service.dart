import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService extends ChangeNotifier {
  int _steps = 0;
  Stream<StepCount>? _stepCountStream;

  int get steps => _steps;

  Future<void> start() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen(_onStepCount);
    } else {
      print('Permission for activity recognition denied.');
    }
  }

  void _onStepCount(StepCount event) {
    _steps = event.steps;
    notifyListeners();
  }
}
