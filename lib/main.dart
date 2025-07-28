import 'package:brease/reflectionspage.dart';
import 'package:flutter/material.dart';
import 'breathingpage.dart';
import 'groundingpage.dart';

void main() {
  runApp(BreaseApp());
}

class BreaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brease',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
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
      ),
    );
  }
}