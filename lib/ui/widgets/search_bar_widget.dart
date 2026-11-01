import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Ô tìm kiếm sản phẩm với nút xóa nhanh và thiết kế tinh tế
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String initialValue;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Tìm kiếm laptop, PC, linh kiện...',
    required this.onChanged,
    required this.onClear,
    this.initialValue = '',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && widget.initialValue.isEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (val) {
          setState(() {});
          widget.onChanged(val);
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.primaryDark : AppColors.primary,
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onClear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
