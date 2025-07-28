import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class ReflectionsPage extends StatefulWidget {
  const ReflectionsPage({Key? key}) : super(key: key);

  @override
  _ReflectionsPageState createState() => _ReflectionsPageState();
}

class _ReflectionsPageState extends State<ReflectionsPage> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  TextEditingController _controller = TextEditingController();
  Map<String, List<String>> _entries = {};

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
    _loadEntries();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _color1Animation = _createColorTweenSequence(_gradientColors).animate(_bgAnimationController);
    _color2Animation = _createColorTweenSequence(_gradientColors.reversed.toList()).animate(_bgAnimationController);
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    Map<String, List<String>> loaded = {};
    for (var key in keys) {
      if (key.startsWith('journal_')) {
        final raw = prefs.getString(key) ?? '';
        loaded[key] = raw.isNotEmpty ? raw.split("|||") : [];
      }
    }
    setState(() {
      _entries = loaded;
    });
  }

  String _dateToKey(DateTime date) {
    return 'journal_${date.year}-${date.month}-${date.day}';
  }

  bool _hasEntry(DateTime day) {
    final key = _dateToKey(day);
    final entries = _entries[key];
    return entries != null && entries.isNotEmpty;
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dateToKey(_selectedDay);

    final newText = _controller.text.trim();
    if (newText.isEmpty) return;

    final currentList = _entries[key] ?? [];
    currentList.add(newText);

    await prefs.setString(key, currentList.join("|||"));

    setState(() {
      _entries[key] = currentList;
      _controller.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entry added")),
    );
  }

  Future<void> _confirmDeleteEntry(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteEntry(index);
    }
  }

  Future<void> _deleteEntry(int index) async {
    final key = _dateToKey(_selectedDay);
    final list = [...?_entries[key]];
    list.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, list.join("|||"));
    setState(() {
      _entries[key] = list;
    });
  }


  Future<void> _editEntry(int index) async {
    final key = _dateToKey(_selectedDay);
    final list = [...?_entries[key]];
    final originalText = list[index];

    final TextEditingController editController = TextEditingController(text: originalText);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Entry"),
        content: TextField(
          controller: editController,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final editedText = editController.text.trim();
              if (editedText.isNotEmpty) {
                list[index] = editedText;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(key, list.join("|||"));
                setState(() {
                  _entries[key] = list;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _openCalendarModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              Navigator.pop(context);
              _onDaySelected(selectedDay, focusedDay);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white70),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                // Show a gray dot if the day has entries
                if (_hasEntry(day)) {
                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryList = _entries[_dateToKey(_selectedDay)] ?? [];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedBuilder(
        animation: _bgAnimationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1Animation.value!, _color2Animation.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _openCalendarModal,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}",
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: entryList.isEmpty
                        ? const Center(
                      child: Text(
                        "No entries yet for this day.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                        : ListView.builder(
                      itemCount: entryList.length,
                      itemBuilder: (context, index) {
                        final entry = entryList[index];
                        return Card(
                          color: Colors.black54,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              entry,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _editEntry(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteEntry(index),
                                ),

                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black54,
                      hintText: "Write a new reflection...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _saveEntry,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Entry"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
