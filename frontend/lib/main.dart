import 'package:flutter/material.dart';
import 'screens/todo_list_screen.dart';
import 'services/todo_repository.dart';
import 'theme.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO',
      theme: buildAppTheme(),
      home: const _Bootstrap(),
    );
  }
}

/// Ensures an anonymous session exists before showing the todo list.
/// First launch: one network call to /anonymous-session.
/// Every launch after: just a secure-storage read, no network call.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final _repository = TodoRepository();
  late final Future<void> _sessionFuture = _repository.ensureSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not connect to the server.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return TodoListScreen(repository: _repository);
      },
    );
  }
}
