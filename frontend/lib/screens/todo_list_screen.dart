import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_repository.dart';
import '../theme.dart';
import '../widgets/todo_tile.dart';

class TodoListScreen extends StatefulWidget {
  final TodoRepository repository;
  const TodoListScreen({super.key, required this.repository});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final todos = await widget.repository.listTodos();
      setState(() => _todos = todos);
    } catch (_) {
      setState(() => _error = 'Could not load tasks. Pull down to retry.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Optimistic: flip the UI immediately, revert only if the API call fails.
  // This keeps the checkbox feeling instant instead of waiting on a round trip.
  Future<void> _toggle(Todo todo) async {
    final next = !todo.completed;
    setState(() {
      _todos = _todos.map((t) => t.id == todo.id ? t.copyWith(completed: next) : t).toList();
    });
    try {
      await widget.repository.setCompleted(todo.id, next);
    } catch (_) {
      setState(() {
        _todos = _todos.map((t) => t.id == todo.id ? t.copyWith(completed: !next) : t).toList();
      });
      _showError('Could not update that task.');
    }
  }

  Future<void> _delete(Todo todo) async {
    setState(() => _todos = _todos.where((t) => t.id != todo.id).toList());
    try {
      await widget.repository.deleteTodo(todo.id);
    } catch (_) {
      setState(() => _todos = [..._todos, todo]);
      _showError('Could not delete that task.');
    }
  }

  Future<void> _addTodo() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddTodoSheet(),
    );
    final title = result?['title']?.trim();
    if (title == null || title.isEmpty) return;

    final description = result?['description']?.trim();
    try {
      final created = await widget.repository.createTodo(
        title,
        (description == null || description.isEmpty) ? null : description,
      );
      setState(() => _todos = [created, ..._todos]);
    } catch (_) {
      _showError('Could not create that task.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final active = _todos.where((t) => !t.completed).toList();
    final done = _todos.where((t) => t.completed).toList();
    final total = _todos.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodo,
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(total, done.length)),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)),
              )
            else ...[
              _buildSectionHeader('TO DO', active.length),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => TodoTile(
                    todo: active[i],
                    onToggle: () => _toggle(active[i]),
                    onDelete: () => _delete(active[i]),
                  ),
                  childCount: active.length,
                ),
              ),
              _buildSectionHeader('COMPLETED', done.length),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => TodoTile(
                    todo: done[i],
                    onToggle: () => _toggle(done[i]),
                    onDelete: () => _delete(done[i]),
                  ),
                  childCount: done.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int total, int doneCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'My Tasks',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's progress", style: TextStyle(color: Colors.white70)),
                    Text(
                      '$doneCount/$total done',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : doneCount / total,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          '$label — $count',
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _AddTodoSheet extends StatefulWidget {
  const _AddTodoSheet();

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop({
              'title': _titleController.text,
              'description': _descriptionController.text,
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}
