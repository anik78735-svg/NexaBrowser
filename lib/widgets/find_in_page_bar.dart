import 'package:flutter/material.dart';

class FindInPageBar extends StatefulWidget {
  final Function(String query) onSearch;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;
  final int currentMatch;
  final int totalMatches;

  const FindInPageBar({
    super.key,
    required this.onSearch,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    this.currentMatch = 0,
    this.totalMatches = 0,
  });

  @override
  State<FindInPageBar> createState() => _FindInPageBarState();
}

class _FindInPageBarState extends State<FindInPageBar> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2E),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Find in page",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: widget.onSearch,
              ),
            ),
            if (widget.totalMatches > 0)
              Text(
                "${widget.currentMatch}/${widget.totalMatches}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
              onPressed: widget.onPrevious,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              onPressed: widget.onNext,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}