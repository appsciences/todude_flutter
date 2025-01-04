import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_item.dart';
import '../services/todo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentList = 'today';
  final TextEditingController _newTodoController = TextEditingController();
  final FocusNode _newTodoFocus = FocusNode();
  bool isCreatingNew = false;
  final TodoService _todoService = TodoService();
  bool _keyboardHandler(KeyEvent event) {
    if (event is KeyDownEvent && !isCreatingNew) {
      if (event.logicalKey == LogicalKeyboardKey.keyT) {
        setState(() => currentList = 'today');
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() => currentList = 'short_term');
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        setState(() => currentList = 'long_term');
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        setState(() => isCreatingNew = true);
        _newTodoFocus.requestFocus();
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _setupKeyboardListeners();
  }

  void _setupKeyboardListeners() {
    HardwareKeyboard.instance.addHandler(_keyboardHandler);
  }

  Future<void> _addTodoItem(String title) async {
    if (title.trim().isEmpty) return;
    
    print('Adding todo to list: $currentList');
    
    await _todoService.addTodo(title, currentList);
    setState(() {
      isCreatingNew = false;
      _newTodoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isCreatingNew)
              TextField(
                controller: _newTodoController,
                focusNode: _newTodoFocus,
                decoration: const InputDecoration(
                  labelText: 'New Todo Item',
                ),
                onSubmitted: (value) => _addTodoItem(value),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildListTab('Today (T)', 'today'),
                _buildListTab('Short Term (S)', 'short_term'),
                _buildListTab('Long Term (L)', 'long_term'),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<TodoItem>>(
                stream: _todoService.getTodos(currentList),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Stream error: ${snapshot.error}');
                    return Text('Something went wrong ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final todos = snapshot.data!;

                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return ListTile(
                        title: Text(todo.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _todoService.deleteTodo(todo.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(String title, String listType) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => currentList = listType),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              decoration: currentList == listType ? TextDecoration.underline : TextDecoration.none,
              decorationColor: Colors.black,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboardHandler);
    _newTodoController.dispose();
    _newTodoFocus.dispose();
    super.dispose();
  }
} 