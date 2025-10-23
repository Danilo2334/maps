import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';

class Supa {
  static final SupabaseClient instance = SupabaseClient(
    Env.supabaseUrl,
    Env.supabaseAnonKey,
  );
}
