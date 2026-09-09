import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../theme.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.completed ? AppColors.purple : Colors.transparent,
                border: Border.all(
                  color: todo.completed ? AppColors.purple : Colors.black26,
                  width: 2,
                ),
              ),
              child: todo.completed
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: todo.completed ? TextDecoration.lineThrough : null,
                    color: todo.completed ? Colors.black45 : Colors.black87,
                  ),
                ),
                if (todo.description != null && todo.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    todo.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      decoration: todo.completed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.black38),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
