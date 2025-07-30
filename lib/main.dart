import 'package:flutter/material.dart';
import 'package:brease/reflectionspage.dart';
import 'breathingpage.dart';
import 'groundingpage.dart';

import 'affirmations_manager.dart';
import 'affirmations_popup.dart';

void main() {
  runApp(BreaseApp());
}

class BreaseApp extends StatefulWidget {
  @override
  _BreaseAppState createState() => _BreaseAppState();
}

class _BreaseAppState extends State<BreaseApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brease',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        dialogBackgroundColor: Colors.transparent,
      ),
      home: HomeWithAffirmations(),
    );
  }
}

class HomeWithAffirmations extends StatefulWidget {
  @override
  _HomeWithAffirmationsState createState() => _HomeWithAffirmationsState();
}

class _HomeWithAffirmationsState extends State<HomeWithAffirmations> {
  final AffirmationsManager _affirmationsManager = AffirmationsManager();

  @override
  void initState() {
    super.initState();
    _affirmationsManager.load().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAffirmationPopup();
      });
    });
  }

  void _showAffirmationPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AffirmationPopup(manager: _affirmationsManager),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      onFloatingButtonPressed: _showAffirmationPopup,
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onFloatingButtonPressed;

  const HomePage({Key? key, required this.onFloatingButtonPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Brease - Breathe with ease'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Breathing'),
              Tab(text: 'Grounding'),
              Tab(text: 'Reflections'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BreathingPage(),
            GroundingPage(),
            ReflectionsPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Show Affirmation',
          child: const Icon(Icons.wb_sunny),
          onPressed: onFloatingButtonPressed,
        ),
      ),
    );
  }
}
