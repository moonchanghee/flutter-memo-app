import 'package:flutter/material.dart';
import '../data/notes_repository.dart';
import 'widgets/category_drawer.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final repo = NotesRepository();

  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    setState(() => loading = true);
    try {
      categories = await repo.fetchCategories();
      notes = await repo.fetchNotes(categoryId: selectedCategoryId);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectCategory(String? categoryId) async {
    setState(() => selectedCategoryId = categoryId);
    await _reloadAll();
  }

  Future<void> _send(String text) async {
    // 화면에 즉시 보이게 optimistic 추가하고 싶으면 여기서 notes에 먼저 add해도 됨
    await repo.sendMemo(text);
    await _reloadAll(); // MVP는 일단 리로드로 간단히
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCategoryId == null ? '전체 메모' : '카테고리 메모'),
        actions: [
          IconButton(onPressed: _reloadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: CategoryDrawer(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        onSelect: _selectCategory,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                ? const Center(child: Text('메모가 없어'))
                : ListView.builder(
                    reverse: true, // 카톡처럼 아래가 최신
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      final isPending =
                          (n['status']?.toString() ?? '') != 'done';
                      return ChatBubble(
                        text: n['content']?.toString() ?? '',
                        isPending: isPending,
                        timeText: _formatTime(n['created_at']),
                      );
                    },
                  ),
          ),
          ChatInput(onSend: _send),
        ],
      ),
    );
  }
}
