import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/todo_item.dart';

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

  @override
  void initState() {
    super.initState();
    _setupKeyboardListeners();
  }

  void _setupKeyboardListeners() {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (event is RawKeyDownEvent) {
        if (!isCreatingNew) {
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
      }
    });
  }

  Future<void> _addTodoItem(String title) async {
    if (title.trim().isEmpty) return;

    final todoItem = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      listType: currentList,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('todos')
        .doc(todoItem.id)
        .set(todoItem.toMap());

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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('todos')
                    .where('listType', isEqualTo: currentList)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final todos = snapshot.data!.docs.map((doc) {
                    return TodoItem.fromMap(
                        doc.data() as Map<String, dynamic>);
                  }).toList();

                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return ListTile(
                        title: Text(todo.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('todos')
                                .doc(todo.id)
                                .delete();
                          },
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
          decoration: BoxDecoration(
            color: currentList == listType ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: currentList == listType ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newTodoController.dispose();
    _newTodoFocus.dispose();
    super.dispose();
  }
} 