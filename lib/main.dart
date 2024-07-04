import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';

void main() {
  runApp(MeditationApp());
}

class MeditationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  double _progress = 0.0;
  String _phase = "Inhale";
  int _seconds = 4;
  bool _isRunning = false;

  void _startTimer(int inhaleSeconds, int holdSeconds, int exhaleSeconds) {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _phase = "Inhale";
      _seconds = inhaleSeconds;
    });

    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.05 / _seconds;
        if (_progress >= 1.0) {
          _progress = 0.0;
          if (_phase == "Inhale") {
            _phase = "Hold";
            _seconds = holdSeconds;
          } else if (_phase == "Hold") {
            _phase = "Exhale";
            _seconds = exhaleSeconds;
          } else if (_phase == "Exhale") {
            _phase = "Inhale";
            _seconds = inhaleSeconds;
          }
        }
      });
    });
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _progress = 0.0;
      _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Brease')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 10.0,
              percent: _progress,
              center: Text(
                _phase,
                style: TextStyle(fontSize: 20.0),
              ),
              progressColor: Colors.blue,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : () {
                    _startTimer(4, 4, 6); // Short button: inhale 4s, hold 2s, exhale 6s
                  },
                  child: Text(_isRunning ? 'Stop' : 'Short'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : () {
                    _startTimer(4, 6, 8); // Long button: inhale 4s, hold 6s, exhale 8s
                  },
                  child: Text('Long'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
