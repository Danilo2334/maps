import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class NegocioRepository {
  final SupabaseClient _db = Supa.instance;

  Future<List<Map<String, dynamic>>> list({String? categoria, String? term}) async {
    var q = _db.from('features').select().eq('kind', 'negocio');
    if (categoria != null && categoria.trim().isNotEmpty) {
      q = q.filter('props->>categoria', 'eq', categoria.trim());
    }
    if (term != null && term.trim().isNotEmpty) {
      final t = term.trim();
      q = q.or("props->>nombre.ilike.%$t%,props->>categoria.ilike.%$t%");
    }
    final data = await q.order('updated_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> insert({required double lat, required double lng, required Map<String, dynamic> props}) async {
    await _db.from('features').insert({'kind': 'negocio', 'lat': lat, 'lng': lng, 'props': props});
  }

  Future<void> update({required String id, required Map<String, dynamic> props}) async {
    await _db.from('features').update({'props': props, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _db.from('features').delete().eq('id', id);
  }

  RealtimeChannel subscribe(void Function() onChange) {
    return _db
        .channel('public:features')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'features', callback: (_) => onChange())
        .subscribe();
  }
}
