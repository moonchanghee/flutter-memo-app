import '../../../core/supabase_client.dart';

class NotesRepository {
  Future<Map<String, dynamic>> sendMemo(String text) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요해');
    }

    // 1) notes에 먼저 저장 (pending)
    final inserted = await supabase
        .from('notes')
        .insert({'user_id': user.id, 'content': text, 'status': 'pending'})
        .select()
        .single();

    final noteId = inserted['id'] as String;

    // 2) Edge Function 호출 (분류 실행)
    await supabase.functions.invoke('analyze_note', body: {'note_id': noteId});

    return inserted;
  }

  Future<List<Map<String, dynamic>>> fetchNotes({String? categoryId}) async {
    var q = supabase
        .from('notes')
        .select('id, content, status, category_id, created_at');

    if (categoryId != null) {
      q = q.eq('category_id', categoryId);
    }

    final res = await q.order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final res = await supabase
        .from('categories')
        .select('id, name, slug')
        .order('created_at', ascending: true);

    return (res as List).cast<Map<String, dynamic>>();
  }
}
