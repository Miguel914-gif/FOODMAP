import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';
import 'restaurant_form_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurante;

  const RestaurantDetailsScreen({super.key, required this.restaurante});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final RestaurantRepository _repository = RestaurantRepository();

  bool excluindo = false;
  bool abrindoMapa = false;

  static const Color fundo = Color(0xFF0D0F12);
  static const Color superficie = Color(0xFF181B20);
  static const Color laranja = Color(0xFFFF6B35);
  static const Color texto = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9CA3AF);
  static const Color borda = Color(0xFF30343D);

  Future<void> _abrirGoogleMaps({required bool rota}) async {
    final endereco = widget.restaurante.endereco.trim();

    if (endereco.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este restaurante não possui endereço cadastrado.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    setState(() => abrindoMapa = true);

    try {
      final destino = Uri.encodeComponent(endereco);

      final url = rota
          ? Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=$destino',
            )
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$destino',
            );

      final abriu = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!abriu && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir o mapa. Tente novamente.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => abrindoMapa = false);
      }
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: superficie,
          title: const Text(
            'Excluir restaurante',
            style: TextStyle(color: texto),
          ),
          content: Text(
            'Tem certeza que deseja excluir '
            '"${widget.restaurante.nome}"?\n\n'
            'Esta ação não poderá ser desfeita.',
            style: const TextStyle(color: textoSecundario),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: textoSecundario),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
              ),
              child: const Text('EXCLUIR'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _excluir();
  }

  Future<void> _excluir() async {
    setState(() => excluindo = true);

    try {
      await _repository.excluirRestaurante(widget.restaurante.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurante excluído com sucesso!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => excluindo = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir o restaurante: $e'),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurante = widget.restaurante;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Detalhes do restaurante'),
        backgroundColor: fundo,
        foregroundColor: texto,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO
            SizedBox(
              width: double.infinity,
              height: 240,
              child: restaurante.fotoUrl.isNotEmpty
                  ? Image.network(
                      restaurante.fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _fotoPadrao();
                      },
                    )
                  : _fotoPadrao(),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME
                  Text(
                    restaurante.nome,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // CATEGORIA
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: laranja),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurante.categoria,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // AVALIAÇÃO
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final estrela = index + 1;

                        return Icon(
                          estrela <= restaurante.avaliacao
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFC857),
                          size: 28,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        restaurante.avaliacao.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: texto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ENDEREÇO
                  _InfoSection(
                    icon: Icons.location_on_outlined,
                    title: 'Endereço',
                    text: restaurante.endereco,
                  ),
                  const SizedBox(height: 14),

                  // BOTÃO GOOGLE MAPS
                  _BotaoMapa(
                    icone: Icons.map_outlined,
                    texto: 'VER NO GOOGLE MAPS',
                    carregando: abrindoMapa,
                    preenchido: false,
                    onPressed: abrindoMapa
                        ? null
                        : () => _abrirGoogleMaps(rota: false),
                  ),
                  const SizedBox(height: 10),

                  // BOTÃO ROTA
                  _BotaoMapa(
                    icone: Icons.directions_outlined,
                    texto: 'TRAÇAR ROTA',
                    carregando: abrindoMapa,
                    preenchido: true,
                    onPressed: abrindoMapa
                        ? null
                        : () => _abrirGoogleMaps(rota: true),
                  ),
                  const SizedBox(height: 25),

                  // DESCRIÇÃO
                  _InfoSection(
                    icon: Icons.description_outlined,
                    title: 'Descrição',
                    text: restaurante.descricao,
                  ),
                  const SizedBox(height: 20),

                  // FAVORITO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: superficie,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borda),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          restaurante.isFavorito
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: restaurante.isFavorito
                              ? Colors.redAccent
                              : textoSecundario,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            restaurante.isFavorito
                                ? 'Restaurante favorito'
                                : 'Não está nos favoritos',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: texto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // EDITAR
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: excluindo
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RestaurantFormScreen(
                                    restaurante: restaurante,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'EDITAR RESTAURANTE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // EXCLUIR
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: excluindo ? null : _confirmarExclusao,
                      icon: excluindo
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.redAccent,
                              ),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(
                        excluindo ? 'EXCLUINDO...' : 'EXCLUIR RESTAURANTE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPadrao() {
    return Container(
      color: superficie,
      child: const Center(
        child: Icon(Icons.restaurant, size: 90, color: laranja),
      ),
    );
  }
}

class _BotaoMapa extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool carregando;
  final bool preenchido;
  final VoidCallback? onPressed;

  const _BotaoMapa({
    required this.icone,
    required this.texto,
    required this.carregando,
    required this.preenchido,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = carregando
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF6B35),
            ),
          )
        : Icon(icone);

    if (preenchido) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: conteudo,
          label: Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: conteudo,
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF6B35),
          side: const BorderSide(color: Color(0xFFFF6B35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text.isEmpty ? 'Não informado.' : text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9CA3AF),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
