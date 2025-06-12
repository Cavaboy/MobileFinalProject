import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerService extends ChangeNotifier {
  int _steps = 0;
  int _offset = 0;
  DateTime? _lastResetDate;
  Stream<StepCount>? _stepCountStream;

  int get steps => _steps - _offset;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    _offset = prefs.getInt('pedometer_offset') ?? 0;
    final lastResetString = prefs.getString('pedometer_last_reset');
    if (lastResetString != null) {
      _lastResetDate = DateTime.tryParse(lastResetString);
    }
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen(_onStepCount);
    } else {
      print('Permission for activity recognition denied.');
    }
  }

  void _onStepCount(StepCount event) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _offset = event.steps;
      _lastResetDate = today;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pedometer_offset', _offset);
      await prefs.setString('pedometer_last_reset', today.toIso8601String());
    }
    // Handle device step counter reset (e.g., after reboot)
    if (event.steps < _offset) {
      _offset = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pedometer_offset', _offset);
    }
    _steps = event.steps;
    // Always use the raw difference for sensitivity
    int todaySteps = _steps - _offset;
    if (todaySteps < 0) todaySteps = 0;
    notifyListeners();
  }
}
