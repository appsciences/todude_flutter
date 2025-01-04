class TodoItem {
  final String id;
  final String userId;
  final String title;
  final String listType; // 'today', 'short_term', 'long_term'
  final DateTime createdAt;
  final bool completed;

  TodoItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.listType,
    required this.createdAt,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'listType': listType,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      listType: map['listType'],
      createdAt: DateTime.parse(map['createdAt']),
      completed: map['completed'] ?? false,
    );
  }
} 