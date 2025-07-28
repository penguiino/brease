import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class GroundingPage extends StatefulWidget {
  const GroundingPage({Key? key}) : super(key: key);

  @override
  _GroundingPageState createState() => _GroundingPageState();
}

class _GroundingPageState extends State<GroundingPage> with TickerProviderStateMixin {
  final List<String> _groundingPrompts = [
    "Look around and name 5 things you can see.",
    "Touch 4 different textures nearby.",
    "Listen for 3 distinct sounds.",
    "Identify 2 different smells.",
    "Notice 1 thing you can taste.",
    "Wiggle your fingers and toes.",
    "Feel your feet on the floor.",
    "Take a moment to notice your breathing.",
  ];

  int _currentPromptIndex = 0;
  bool _showCompletionMessage = false;
  bool _isStarted = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
          weight: 1,
        ),
      );
    }
    return TweenSequence<Color?>(items);
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _color1Animation = _createColorTweenSequence(_gradientColors).animate(_bgAnimationController);
    _color2Animation = _createColorTweenSequence(_gradientColors.reversed.toList()).animate(_bgAnimationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
  }

  Future<void> _nextPrompt() async {
    if (_showCompletionMessage) return;

    if (_currentPromptIndex == _groundingPrompts.length - 1) {
      setState(() {
        _showCompletionMessage = true;
      });
      return;
    }

    await _animationController.reverse();
    setState(() {
      _currentPromptIndex = (_currentPromptIndex + 1) % _groundingPrompts.length;
    });
    await _vibrate();
    _animationController.value = 0.0;
    await _animationController.forward();
  }

  Future<void> _prevPrompt() async {
    if (_showCompletionMessage) return;

    await _animationController.reverse();
    setState(() {
      _currentPromptIndex--;
      if (_currentPromptIndex < 0) {
        _currentPromptIndex = _groundingPrompts.length - 1;
      }
    });
    await _vibrate();
    _animationController.value = 0.0;
    await _animationController.forward();
  }

  void _restartSession() async {
    await _animationController.reverse();
    setState(() {
      _currentPromptIndex = 0;
      _showCompletionMessage = false;
      _isStarted = false;
    });
    await _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_currentPromptIndex + 1) / _groundingPrompts.length;

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
                  _color1Animation.value ?? Colors.teal.shade700,
                  _color2Animation.value ?? Colors.teal.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: _showCompletionMessage
                  ? _buildCompletionMessage()
                  : (!_isStarted ? _buildStartScreen() : _buildPromptView(progressPercent)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Grounding Exercise",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isStarted = true;
              _animationController.forward(from: 0);
            });
          },
          child: const Text("Start"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptView(double progressPercent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Grounding Exercise",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.9 + 0.1 * _fadeAnimation.value.clamp(0.0, 1.0),
                child: Text(
                  _groundingPrompts[_currentPromptIndex],
                  key: ValueKey<int>(_currentPromptIndex),
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        LinearProgressIndicator(
          value: progressPercent,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          minHeight: 8,
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedButton(
              onPressed: _prevPrompt,
              icon: Icons.arrow_back,
              label: "Previous",
            ),
            const SizedBox(width: 20),
            _AnimatedButton(
              onPressed: _nextPrompt,
              icon: Icons.arrow_forward,
              label: "Next",
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCompletionMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.greenAccent.shade400,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.shade700.withAlpha((0.6 * 255).round()),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            "You’ve completed a grounding session.\nGreat job!\nFeel free to repeat it as often as you like.",
            style: TextStyle(fontSize: 22, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _restartSession,
            child: const Text("Restart"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  __AnimatedButtonState createState() => __AnimatedButtonState();
}

class __AnimatedButtonState extends State<_AnimatedButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        widget.onPressed();
      },
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton.icon(
          icon: Icon(widget.icon),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
