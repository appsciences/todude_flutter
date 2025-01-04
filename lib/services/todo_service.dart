import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_item.dart';
import 'auth_service.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get todos stream for current user
  Stream<List<TodoItem>> getTodos(String listType) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    // Add print statements for debugging
    print('Fetching todos for user: $userId, listType: $listType');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .where('listType', isEqualTo: listType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Received ${snapshot.docs.length} todos');
          return snapshot.docs
              .map((doc) => TodoItem.fromMap(doc.data()))
              .toList();
        });
  }

  // Add todo
  Future<void> addTodo(String title, String listType) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final todoItem = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      listType: listType,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoItem.id)
        .set(todoItem.toMap());
  }

  // Delete todo
  Future<void> deleteTodo(String todoId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .delete();
  }

  // Toggle todo completion
  Future<void> toggleTodoCompletion(TodoItem todo) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todo.id)
        .update({'completed': !todo.completed});
  }
} 