import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../data/negocio_repository.dart';

const _pasto = LatLng(1.2136, -77.2811);

class MapNegociosPage extends StatefulWidget {
  const MapNegociosPage({super.key});

  @override
  State<MapNegociosPage> createState() => _MapNegociosPageState();
}

class _MapNegociosPageState extends State<MapNegociosPage> {
  final repo = NegocioRepository();
  final MapController _map = MapController();
  LatLng _center = _pasto;

  final _qCtrl = TextEditingController();
  String? _categoriaFilter;
  List<Map<String, dynamic>> _items = [];
  RealtimeChannel? _rt;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _load();
    _rt = repo.subscribe(_load);
  }

  @override
  void dispose() {
    _rt?.unsubscribe();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (await Geolocator.isLocationServiceEnabled()) {
      final p = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(p.latitude, p.longitude));
      _map.move(_center, 14);
    }
  }

  Future<void> _load() async {
    try {
      final data = await repo.list(categoria: _categoriaFilter, term: _qCtrl.text);
      if (!mounted) return;
      setState(() => _items = data);
    } on PostgrestException catch (e) {
      _toast(e.message ?? 'Error cargando datos');
    } catch (e) {
      _toast('Error cargando datos: $e');
    }
  }

  Future<void> _onLongPress(TapPosition _, LatLng p) async {
    await _openCreateDialog(p);
  }

  List<Marker> _markers() {
    return _items.map((f) {
      final lat = (f['lat'] as num).toDouble();
      final lng = (f['lng'] as num).toDouble();
      final props = (f['props'] as Map?) ?? {};
      final categoria = props['categoria']?.toString();
      final color = colorPorCategoria(categoria);
      return Marker(
        point: LatLng(lat, lng),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _openDetailSheet(f),
          child: Icon(Icons.location_on, size: 36, color: color),
        ),
      );
    }).toList();
  }

  Future<void> _openCreateDialog(LatLng p) async {
    final nombre = TextEditingController();
    final categoria = TextEditingController(text: 'Tienda');
    final telefono = TextEditingController();
    final horario = TextEditingController(text: 'L-D 08:00-18:00');
    final direccion = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo negocio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lat ${p.latitude.toStringAsFixed(6)}, Lng ${p.longitude.toStringAsFixed(6)}'),
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: categoria, decoration: const InputDecoration(labelText: 'Categoría')),
              TextField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: horario, decoration: const InputDecoration(labelText: 'Horario (ej: L-D 08:00-18:00)')),
              TextField(controller: direccion, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true) {
      if (!Validators.telCol(telefono.text)) {
        _toast('Teléfono no válido. Usa 10 dígitos (cel) o fijo local.');
        return;
      }
      if (!Validators.horarioSimple(horario.text)) {
        _toast('Formato de horario inválido. Ej: L-D 08:00-18:00');
        return;
      }
      try {
        await repo.insert(
          lat: p.latitude,
          lng: p.longitude,
          props: {
            'nombre': nombre.text.trim().isEmpty ? 'Negocio' : nombre.text.trim(),
            'categoria': categoria.text.trim(),
            'telefono': telefono.text.trim(),
            'horario': horario.text.trim(),
            'direccion': direccion.text.trim(),
          },
        );
        _toast('Negocio guardado');
      } on PostgrestException catch (e) {
        _toast(e.message ?? 'Error al guardar');
      } catch (e) {
        _toast('Error al guardar: $e');
      }
    }
  }

  void _openDetailSheet(Map<String, dynamic> f) {
    final id = f['id'] as String;
    final lat = (f['lat'] as num).toDouble();
    final lng = (f['lng'] as num).toDouble();
    final props = (f['props'] as Map?) ?? {};
    final nombre = props['nombre']?.toString() ?? 'Negocio';
    final categoria = props['categoria']?.toString() ?? '';
    final telefono = props['telefono']?.toString() ?? '';
    final horario = props['horario']?.toString() ?? '';
    final direccion = props['direccion']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Categoría: $categoria'),
            if (direccion.isNotEmpty) Text('Dirección: $direccion'),
            Text('Tel: $telefono'),
            Text('Horario: $horario'),
            Text('Ubicación: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openEditDialog(f);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await repo.delete(id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _toast('Negocio eliminado');
                    } on PostgrestException catch (e) {
                      _toast(e.message ?? 'Error al eliminar');
                    } catch (e) {
                      _toast('Error al eliminar: $e');
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(Map<String, dynamic> f) async {
    final id = f['id'] as String;
    final props = (f['props'] as Map?) ?? {};
    final nombre = TextEditingController(text: props['nombre']?.toString() ?? '');
    final categoria = TextEditingController(text: props['categoria']?.toString() ?? '');
    final telefono = TextEditingController(text: props['telefono']?.toString() ?? '');
    final horario = TextEditingController(text: props['horario']?.toString() ?? '');
    final direccion = TextEditingController(text: props['direccion']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar negocio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: categoria, decoration: const InputDecoration(labelText: 'Categoría')),
              TextField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: horario, decoration: const InputDecoration(labelText: 'Horario')),
              TextField(controller: direccion, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true) {
      if (!Validators.telCol(telefono.text)) {
        _toast('Teléfono no válido. Usa 10 dígitos (cel) o fijo local.');
        return;
      }
      if (!Validators.horarioSimple(horario.text)) {
        _toast('Formato de horario inválido. Ej: L-D 08:00-18:00');
        return;
      }
      try {
        await repo.update(id: id, props: {
          'nombre': nombre.text.trim(),
          'categoria': categoria.text.trim(),
          'telefono': telefono.text.trim(),
          'horario': horario.text.trim(),
          'direccion': direccion.text.trim(),
        });
        _toast('Negocio actualizado');
      } on PostgrestException catch (e) {
        _toast(e.message ?? 'Error al actualizar');
      } catch (e) {
        _toast('Error al actualizar: $e');
      }
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final markers = _markers();
    final categorias = _items
        .map((e) => (e['props'] as Map?)?['categoria']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Censo de Negocios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final p = await Geolocator.getCurrentPosition();
              _map.move(LatLng(p.latitude, p.longitude), 15);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar por nombre o categoría...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _categoriaFilter,
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) {
                    setState(() => _categoriaFilter = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                    onLongPress: _onLongPress,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.censo_negocios',
                    ),
                    MarkerLayer(markers: markers),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 8),
                            itemBuilder: (_, i) {
                              final f = _items[i];
                              final props = (f['props'] as Map?) ?? {};
                              final nombre = props['nombre']?.toString() ?? 'Negocio';
                              final categoria = props['categoria']?.toString() ?? '';
                              final telefono = props['telefono']?.toString() ?? '';
                              final color = colorPorCategoria(categoria);
                              return ListTile(
                                leading: Icon(Icons.storefront, color: color),
                                title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('$categoria • $telefono', maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  final lat = (f['lat'] as num).toDouble();
                                  final lng = (f['lng'] as num).toDouble();
                                  _map.move(LatLng(lat, lng), 17);
                                  _openDetailSheet(f);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    );
  }
}
