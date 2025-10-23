class Validators {
  static bool telCol(String t) {
    final s = t.replaceAll(RegExp(r'\s+'), '').trim();
    if (s.isEmpty) return false;
    final cel = RegExp(r'^3\d{9}$'); // Celular colombiano (10 dígitos iniciando en 3)
    final fijo = RegExp(r'^\d{7}$'); // Teléfono fijo local
    final fijoIndic = RegExp(r'^\d{9,10}$'); // Indicativo (2-3 dígitos) + fijo (7 dígitos)
    return cel.hasMatch(s) || fijo.hasMatch(s) || fijoIndic.hasMatch(s);
  }

  static bool horarioSimple(String h) {
    final s = h.trim();
    if (s.isEmpty) return false;
    const dias = r'(L|Ma|Mi|J|V|S|D)';
    final re = RegExp('^$dias([- ]$dias)?\\s+\\d{1,2}:\\d{2}-\\d{1,2}:\\d{2}\$');
    return re.hasMatch(s);
  }
}
