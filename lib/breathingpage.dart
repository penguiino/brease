import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BreathingPage extends StatefulWidget {
  const BreathingPage({Key? key}) : super(key: key);

  @override
  _BreathingPageState createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> with TickerProviderStateMixin {
  Timer? _timer;
  double _progress = 0.0;
  String _phase = "Inhale";
  int _seconds = 4;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _showComplete = false;
  int _remainingSeconds = 4;

  int _inhaleDuration = 4;
  int _holdDuration = 4;
  int _exhaleDuration = 6;

  final Map<String, List<int>> _breathingPresets = {
    "Box Breathing (4-4-4)": [4, 4, 4],
    "4-7-8 Breathing": [4, 7, 8],
    "Relaxing Breath (5-0-5)": [5, 0, 5],
    "Extended Exhale (4-0-6)": [4, 0, 6],
  };

  final Map<String, String> _presetDescriptions = {
    "Box Breathing (4-4-4)": "Calms nerves, sharpens focus",
    "4-7-8 Breathing": "Helps you relax and fall asleep",
    "Relaxing Breath (5-0-5)": "Balances and centers the breath",
    "Extended Exhale (4-0-6)": "Promotes stress relief",
  };

  String? _selectedPresetKey;
  bool _showSuggestions = true;

  late AnimationController _bgAnimationController;
  late Animation<Color?> _color1Animation;
  late Animation<Color?> _color2Animation;

  final List<Color> _gradientColors = [
    Colors.teal.shade700,
    Colors.teal.shade500,
    Colors.green.shade600,
    Colors.green.shade400,
    Colors.blue.shade600,
    Colors.blue.shade400,
  ];

  TweenSequence<Color?> _createColorTweenSequence(List<Color> colors) {
    final items = <TweenSequenceItem<Color?>>[];
    for (int i = 0; i < colors.length; i++) {
      final next = colors[(i + 1) % colors.length];
      items.add(
        TweenSequenceItem(
          tween: ColorTween(begin: colors[i], end: next),
          weight: 1.0,
        ),
      );
    }
    return TweenSequence<Color?>(items);
  }

  @override
  void initState() {
    super.initState();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _color1Animation = _createColorTweenSequence(_gradientColors).animate(_bgAnimationController);
    _color2Animation = _createColorTweenSequence(_gradientColors.reversed.toList()).animate(_bgAnimationController);

    _updateSelectedPresetKey();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _updateSelectedPresetKey() {
    final match = _breathingPresets.entries.firstWhere(
          (entry) =>
      entry.value[0] == _inhaleDuration &&
          entry.value[1] == _holdDuration &&
          entry.value[2] == _exhaleDuration,
      orElse: () => MapEntry('', [-1, -1, -1]),
    );

    setState(() {
      if (match.key == '') {
        _selectedPresetKey = null;
      } else {
        _selectedPresetKey = match.key;
      }
      _showSuggestions = !_isRunning;
    });
  }

  void _startTimer(int inhaleSeconds, int holdSeconds, int exhaleSeconds, String timerType) {
    setState(() {
      _inhaleDuration = inhaleSeconds;
      _holdDuration = holdSeconds;
      _exhaleDuration = exhaleSeconds;
      _isRunning = true;
      _isPaused = false;
      _progress = 0.0;
      _phase = "Inhale";
      _seconds = inhaleSeconds;
      _remainingSeconds = inhaleSeconds;
      _showComplete = false;
      _showSuggestions = false;
    });

    WakelockPlus.enable();
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 0.1 / _seconds;
        _remainingSeconds = (_seconds * (1 - _progress)).ceil();

        if (_progress >= 1.0) {
          _progress = 0.0;

          if (_phase == "Inhale") {
            if (_holdDuration > 0) {
              _phase = "Hold";
              _seconds = _holdDuration;
            } else {
              _phase = "Exhale";
              _seconds = _exhaleDuration;
            }
          } else if (_phase == "Hold") {
            _phase = "Exhale";
            _seconds = _exhaleDuration;
          } else if (_phase == "Exhale") {
            _phase = "Inhale";
            _seconds = _inhaleDuration;
          }

          if (_seconds == 0) {
            _seconds = 1;
          }

          _remainingSeconds = _seconds;
        }
      });
    });
  }

  void _stopTimer({bool showComplete = true}) {
    setState(() {
      _isRunning = false;
      _progress = 0.0;
      _timer?.cancel();
      _showComplete = showComplete;
      _updateSelectedPresetKey();
    });

    WakelockPlus.disable();
  }

  void _pauseResume() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Color _getPhaseColor() {
    switch (_phase) {
      case "Inhale":
        return Colors.greenAccent;
      case "Hold":
        return Colors.orangeAccent;
      case "Exhale":
        return Colors.blueAccent;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSliders() {
    return Column(
      children: [
        _buildSlider("Inhale", _inhaleDuration, (val) {
          setState(() {
            _inhaleDuration = val.toInt();
            _updateSelectedPresetKey();
          });
        }),
        _buildSlider("Hold", _holdDuration, (val) {
          setState(() {
            _holdDuration = val.toInt();
            _updateSelectedPresetKey();
          });
        }),
        _buildSlider("Exhale", _exhaleDuration, (val) {
          setState(() {
            _exhaleDuration = val.toInt();
            _updateSelectedPresetKey();
          });
        }),
      ],
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<double> onChanged) {
    final isHold = label == "Hold";
    return Column(
      children: [
        Text("$label: $value sec", style: const TextStyle(color: Colors.white70)),
        Slider(
          min: isHold ? 0 : 2,
          max: 10,
          divisions: isHold ? 10 : 8,
          value: value.toDouble(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSuggestionBox() {
    if (!_showSuggestions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedPresetKey,
        hint: const Text("Select a preset", style: TextStyle(color: Colors.white)),
        dropdownColor: Colors.black87,
        style: const TextStyle(color: Colors.white70),
        onChanged: (key) {
          if (key != null) {
            setState(() {
              _inhaleDuration = _breathingPresets[key]![0];
              _holdDuration = _breathingPresets[key]![1];
              _exhaleDuration = _breathingPresets[key]![2];
              _selectedPresetKey = key;
              _updateSelectedPresetKey();
            });
          }
        },
        items: _breathingPresets.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key),
                Text(
                  _presetDescriptions[entry.key] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Breathing Techniques"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _presetDescriptions.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text("${entry.key}: ${entry.value}"),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1Animation.value!,
                  _color2Animation.value!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                child!,
                Positioned(top: 0, right: 0, child: _buildSuggestionBox()),
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white70),
                    onPressed: _showInfoDialog,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: _progress,
                progressColor: _getPhaseColor(),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showComplete ? "Done" : _phase,
                      style: const TextStyle(fontSize: 34.0, color: Colors.white70),
                    ),
                    if (!_showComplete)
                      Text(
                        '$_remainingSeconds s',
                        style: const TextStyle(fontSize: 20.0, color: Colors.white60),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (!_isRunning) _buildSliders(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning) ...[
                    ElevatedButton(
                      onPressed: () => _startTimer(_inhaleDuration, _holdDuration, _exhaleDuration, 'custom'),
                      child: const Text('Start'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _pauseResume,
                      child: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => _stopTimer(),
                      child: const Text('Stop'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
