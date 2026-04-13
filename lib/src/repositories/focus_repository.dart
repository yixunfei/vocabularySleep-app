import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import '../services/database_service.dart';

abstract class FocusRepository {
  String? getSetting(String key);

  void setSetting(String key, String value);

  void insertTimerRecord(TomatoTimerRecord record);

  List<TodoItem> getTodos();

  int insertTodo(TodoItem item);

  void updateTodo(TodoItem item);

  void deleteTodo(int id);

  void clearCompletedTodos();

  void reorderTodos(List<int> orderedIds);

  List<PlanNote> getNotes();

  void insertNote(PlanNote note);

  void updateNote(PlanNote note);

  void deleteNote(int id);

  void deleteNotes(List<int> ids);

  void reorderNotes(List<int> orderedIds);

  List<TomatoTimerRecord> getTimerRecords({int limit = 30});
}

class DatabaseFocusRepository implements FocusRepository {
  const DatabaseFocusRepository(this._database);

  final AppDatabaseService _database;

  @override
  String? getSetting(String key) => _database.getSetting(key);

  @override
  void setSetting(String key, String value) => _database.setSetting(key, value);

  @override
  void insertTimerRecord(TomatoTimerRecord record) {
    _database.insertTimerRecord(record);
  }

  @override
  List<TodoItem> getTodos() => _database.getTodos();

  @override
  int insertTodo(TodoItem item) => _database.insertTodo(item);

  @override
  void updateTodo(TodoItem item) => _database.updateTodo(item);

  @override
  void deleteTodo(int id) => _database.deleteTodo(id);

  @override
  void clearCompletedTodos() => _database.clearCompletedTodos();

  @override
  void reorderTodos(List<int> orderedIds) => _database.reorderTodos(orderedIds);

  @override
  List<PlanNote> getNotes() => _database.getNotes();

  @override
  void insertNote(PlanNote note) => _database.insertNote(note);

  @override
  void updateNote(PlanNote note) => _database.updateNote(note);

  @override
  void deleteNote(int id) => _database.deleteNote(id);

  @override
  void deleteNotes(List<int> ids) => _database.deleteNotes(ids);

  @override
  void reorderNotes(List<int> orderedIds) => _database.reorderNotes(orderedIds);

  @override
  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    return _database.getTimerRecords(limit: limit);
  }
}
