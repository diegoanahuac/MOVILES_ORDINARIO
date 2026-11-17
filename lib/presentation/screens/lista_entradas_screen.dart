import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/errors/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/models/entrada_diario.dart';
import '../widgets/app_drawer.dart';
import '../widgets/entrada_card.dart';
import '../widgets/vistas_estado.dart';

/// Lista principal de entradas, cargadas desde SQLite con un FutureBuilder.
class ListaEntradasScreen extends StatefulWidget {
  const ListaEntradasScreen({super.key});

  @override
  State<ListaEntradasScreen> createState() => _ListaEntradasScreenState();
}

class _ListaEntradasScreenState extends State<ListaEntradasScreen> {
  Future<List<EntradaDiario>>? _carga;
  EstadoAnimo? _filtro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carga ??= AppScope.of(context).diario.obtenerTodas();
  }

  void _recargar() =>
      setState(() => _carga = AppScope.of(context).diario.obtenerTodas());

  Future<void> _nueva() async {
    final guardo = await Navigator.pushNamed(context, AppRoutes.nueva);
    if (guardo == true) _recargar();
  }

  Future<void> _abrir(EntradaDiario e) async {
    final cambio = await Navigator.pushNamed(context, AppRoutes.detalle, arguments: e.id);
    if (cambio == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis entradas'),
        actions: [
          PopupMenuButton<EstadoAnimo?>(
            tooltip: 'Filtrar por ánimo',
            icon: Icon(_filtro == null ? Icons.filter_list : Icons.filter_list_alt),
            onSelected: (v) => setState(() => _filtro = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
              for (final a in EstadoAnimo.values)
                PopupMenuItem(value: a, child: Text('${a.emoji}  ${a.etiqueta}')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.edit),
        label: const Text('Nueva entrada'),
      ),
      body: FutureBuilder<List<EntradaDiario>>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final error = snap.error;
            return VistaError(
              mensaje: error is AppException ? error.mensaje : 'Ocurrió un error inesperado.',
              reintentar: _recargar,
            );
          }
          final todas = snap.data ?? const [];
          final entradas =
              _filtro == null ? todas : todas.where((e) => e.animo == _filtro).toList();
          if (entradas.isEmpty) {
            return VistaVacia(
              icono: Icons.auto_stories_outlined,
              titulo: todas.isEmpty
                  ? 'Todavía no escribes nada'
                  : 'No hay entradas con ese ánimo',
              detalle: todas.isEmpty
                  ? 'Toca "Nueva entrada" para guardar tu día con una foto, tu voz y el lugar donde estás.'
                  : null,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: entradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => EntradaCard(
                entrada: entradas[i],
                alTocar: () => _abrir(entradas[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}
