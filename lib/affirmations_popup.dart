import 'dart:math';
import 'package:flutter/material.dart';
import 'affirmations_manager.dart';

class AffirmationPopup extends StatefulWidget {
  final AffirmationsManager manager;

  const AffirmationPopup({Key? key, required this.manager}) : super(key: key);

  @override
  _AffirmationPopupState createState() => _AffirmationPopupState();
}

class _AffirmationPopupState extends State<AffirmationPopup> {
  String? _currentAffirmation;
  bool _isEditing = false;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickRandomAffirmation();
  }

  void _pickRandomAffirmation() {
    if (widget.manager.affirmations.isEmpty) {
      _currentAffirmation = null;
    } else {
      final rnd = Random();
      _currentAffirmation = widget.manager.affirmations[rnd.nextInt(widget.manager.affirmations.length)];
    }
  }

  void _addAffirmation() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    await widget.manager.add(text);
    _addController.clear();
    setState(() {
      _pickRandomAffirmation();
      _isEditing = false; // auto-exit edit mode after adding
    });
  }

  void _deleteAffirmation(int index) async {
    await widget.manager.delete(index);
    setState(() {
      _pickRandomAffirmation();
      if (widget.manager.affirmations.isEmpty) _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {}, // prevent tap propagation
          child: Material(
            color: Colors.black.withOpacity(0.6), // semi-transparent dark overlay
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Close button top-right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: Colors.white70, size: 28),
                      ),
                    ),
                  ),

                  // Edit toggle button top-left
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => setState(() => _isEditing = !_isEditing),
                        child: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white70, size: 28),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
                    child: _isEditing ? _buildEditor() : _buildAffirmation(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAffirmation() {
    final affirmations = widget.manager.affirmations;

    if (affirmations.isEmpty) {
      return const Text(
        "Add your first affirmation using the ✏️ button!",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentAffirmation ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (affirmations.length > 1) ...[
          const SizedBox(height: 8),
          const Text(
            "Showing a random affirmation each time",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Edit Affirmations",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 200,
          child: widget.manager.affirmations.isEmpty
              ? const Center(
            child: Text("No affirmations yet.", style: TextStyle(color: Colors.white54)),
          )
              : ListView.builder(
            itemCount: widget.manager.affirmations.length,
            itemBuilder: (context, index) {
              final affirmation = widget.manager.affirmations[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(affirmation, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteAffirmation(index),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Material(
          color: Colors.transparent,
          child: TextField(
            controller: _addController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Add new affirmation...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _addAffirmation(),
          ),
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _addAffirmation,
          icon: const Icon(Icons.add),
          label: const Text("Add Affirmation"),
        ),
      ],
    );
  }
}
