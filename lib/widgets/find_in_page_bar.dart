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
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHigh,
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
                style: TextStyle(color: colors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Find in page",
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                ),
                onChanged: widget.onSearch,
              ),
            ),
            if (widget.totalMatches > 0)
              Text(
                "${widget.currentMatch}/${widget.totalMatches}",
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_up, color: colors.onSurface, size: 20),
              onPressed: widget.onPrevious,
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_down, color: colors.onSurface, size: 20),
              onPressed: widget.onNext,
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.onSurface, size: 20),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}