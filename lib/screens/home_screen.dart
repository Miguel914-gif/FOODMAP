import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';
import 'favorites_screen.dart';
import 'restaurant_details_screen.dart';
import 'restaurant_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RestaurantRepository repository = RestaurantRepository();
  final TextEditingController buscaController = TextEditingController();
  final ImagePicker seletorImagem = ImagePicker();

  static const Color fundo = Color(0xFF0D0F12);
  static const Color superficie = Color(0xFF181B20);
  static const Color laranja = Color(0xFFFF6B35);
  static const Color textoPrincipal = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9CA3AF);
  static const Color dourado = Color(0xFFFFC857);

  static const String gifExplorarUrl =
      'https://media.giphy.com/media/l0HlQ7LRalQqdWfao/giphy.gif';

  static const String gifFavoritosUrl =
      'https://media1.giphy.com/media/Gi9dJsd3azHEY/200.gif';

  String termoBusca = '';
  String categoriaSelecionada = 'Todas';
  int abaSelecionada = 0;
  bool salvandoFoto = false;

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  // Converte a imagem Base64 do Firestore em uma imagem do Flutter.
  ImageProvider? _obterImagemPerfil(Map<String, dynamic>? dados) {
    final fotoBase64 = dados?['fotoBase64'];

    if (fotoBase64 is! String || fotoBase64.isEmpty) {
      return null;
    }

    try {
      return MemoryImage(base64Decode(fotoBase64));
    } catch (_) {
      return null;
    }
  }

  // Seleciona uma foto, converte para Base64 e salva no perfil.
  Future<void> _selecionarFotoPerfil(User usuario) async {
    if (salvandoFoto) return;

    try {
      final XFile? imagem = await seletorImagem.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 60,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      // Limite preventivo para reduzir o tamanho do documento Firestore.
      if (bytes.length > 300 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A imagem é muito grande. Escolha uma foto menor.'),
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        salvandoFoto = true;
      });

      final String fotoBase64 = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(usuario.uid).set(
        {'fotoBase64': fotoBase64},
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil salva com sucesso!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar a foto: $e'),
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvandoFoto = false;
        });
      }
    }
  }

  // Remove somente a foto, preservando nome, e-mail e demais dados.
  Future<void> _removerFotoPerfil(User usuario) async {
    if (salvandoFoto) return;

    setState(() {
      salvandoFoto = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(usuario.uid).set(
        {'fotoBase64': null},
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil removida.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível remover a foto: $e'),
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvandoFoto = false;
        });
      }
    }
  }

  // Abre a janela de perfil com opções para adicionar, trocar e remover.
  Future<void> _abrirPerfil(User usuario) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuario.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final dados = snapshot.data?.data();

                final nome =
                    dados?['nome'] as String? ??
                    usuario.displayName ??
                    'Usuário';

                final email = dados?['email'] as String? ?? usuario.email ?? '';

                final imagemPerfil = _obterImagemPerfil(dados);

                return AlertDialog(
                  backgroundColor: superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  title: const Text(
                    'Meu perfil',
                    style: TextStyle(
                      color: textoPrincipal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: laranja.withValues(alpha: 0.18),
                              backgroundImage: imagemPerfil,
                              child: imagemPerfil == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: laranja,
                                      size: 52,
                                    )
                                  : null,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: laranja,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Escolher foto',
                                onPressed: salvandoFoto
                                    ? null
                                    : () async {
                                        await _selecionarFotoPerfil(usuario);

                                        if (dialogContext.mounted) {
                                          atualizarDialogo(() {});
                                        }
                                      },
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textoPrincipal,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: textoSecundario),
                        ),
                        const SizedBox(height: 22),

                        // Adicionar uma foto ou trocar a foto atual.
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: salvandoFoto
                                ? null
                                : () async {
                                    await _selecionarFotoPerfil(usuario);

                                    if (dialogContext.mounted) {
                                      atualizarDialogo(() {});
                                    }
                                  },
                            icon: salvandoFoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              salvandoFoto
                                  ? 'Salvando foto...'
                                  : imagemPerfil == null
                                  ? 'Adicionar foto'
                                  : 'Trocar foto',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: laranja,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: laranja.withValues(
                                alpha: 0.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // Remover aparece somente quando há uma foto.
                        if (imagemPerfil != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: salvandoFoto
                                  ? null
                                  : () async {
                                      await _removerFotoPerfil(usuario);

                                      if (dialogContext.mounted) {
                                        atualizarDialogo(() {});
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remover foto'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (snapshot.hasError) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Não foi possível carregar os dados do perfil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(color: laranja),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: fundo,
        body: Center(
          child: Text(
            'Usuário não encontrado.',
            style: TextStyle(color: textoPrincipal),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: fundo,
      appBar: abaSelecionada == 0
          ? AppBar(
              backgroundColor: fundo,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: laranja.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: laranja,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'FOODMAP',
                          style: TextStyle(
                            color: textoPrincipal,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'DESCUBRA NOVOS SABORES',
                          style: TextStyle(
                            color: textoSecundario,
                            fontSize: 9,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(usuario.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final imagemPerfil = _obterImagemPerfil(
                        snapshot.data?.data(),
                      );

                      return IconButton(
                        tooltip: 'Meu perfil',
                        onPressed: () => _abrirPerfil(usuario),
                        icon: CircleAvatar(
                          radius: 19,
                          backgroundColor: laranja.withValues(alpha: 0.18),
                          backgroundImage: imagemPerfil,
                          child: imagemPerfil == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: laranja,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,

      body: abaSelecionada == 0
          ? _buildExplorar(usuario)
          : const FavoritesScreen(),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: superficie,
          border: Border(top: BorderSide(color: Color(0xFF292D34))),
        ),
        child: SafeArea(
          child: NavigationBar(
            backgroundColor: superficie,
            indicatorColor: laranja.withValues(alpha: 0.16),
            elevation: 0,
            selectedIndex: abaSelecionada,
            onDestinationSelected: (index) {
              setState(() {
                abaSelecionada = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: Image.network(
                  gifExplorarUrl,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.explore_outlined,
                      color: textoSecundario,
                    );
                  },
                ),
                selectedIcon: Image.network(
                  gifExplorarUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.explore_rounded, color: laranja);
                  },
                ),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Image.network(
                  gifFavoritosUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.favorite_border_rounded,
                      color: textoSecundario,
                    );
                  },
                ),
                selectedIcon: Image.network(
                  gifFavoritosUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.favorite_rounded, color: laranja);
                  },
                ),
                label: 'Favoritos',
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: abaSelecionada == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RestaurantFormScreen(),
                  ),
                );
              },
              backgroundColor: laranja,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Adicionar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildExplorar(User usuario) {
    return StreamBuilder<List<Restaurant>>(
      stream: repository.listarRestaurantes(usuario.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: laranja));
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar os restaurantes.\n'
                'Verifique sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textoSecundario),
              ),
            ),
          );
        }

        final todosRestaurantes = snapshot.data ?? [];

        final categorias =
            todosRestaurantes
                .map((restaurante) => restaurante.categoria.trim())
                .where((categoria) => categoria.isNotEmpty)
                .toSet()
                .toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        if (categoriaSelecionada != 'Todas' &&
            !categorias.any(
              (categoria) =>
                  categoria.toLowerCase() == categoriaSelecionada.toLowerCase(),
            )) {
          categoriaSelecionada = 'Todas';
        }

        final restaurantes = todosRestaurantes.where((restaurante) {
          final nome = restaurante.nome.toLowerCase();
          final categoria = restaurante.categoria.toLowerCase();

          final correspondeBusca =
              nome.contains(termoBusca) || categoria.contains(termoBusca);

          final correspondeCategoria =
              categoriaSelecionada == 'Todas' ||
              categoria == categoriaSelecionada.toLowerCase();

          return correspondeBusca && correspondeCategoria;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seu próximo favorito',
                    style: TextStyle(
                      color: textoPrincipal,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Explore lugares especiais e descubra novos sabores.',
                    style: TextStyle(
                      color: textoSecundario,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: buscaController,
                    onChanged: (valor) {
                      setState(() {
                        termoBusca = valor.trim().toLowerCase();
                      });
                    },
                    style: const TextStyle(color: textoPrincipal, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Buscar restaurante ou culinária...',
                      hintStyle: const TextStyle(color: textoSecundario),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: laranja,
                      ),
                      suffixIcon: termoBusca.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                buscaController.clear();
                                setState(() {
                                  termoBusca = '';
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: textoSecundario,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: superficie,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF292D34)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: laranja,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Categorias',
                    style: TextStyle(
                      color: textoPrincipal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoriaChip('Todas'),
                        ...categorias.map(_buildCategoriaChip),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Restaurantes',
                          style: TextStyle(
                            color: textoPrincipal,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${restaurantes.length} '
                        '${restaurantes.length == 1 ? 'local' : 'locais'}',
                        style: const TextStyle(
                          color: textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: todosRestaurantes.isEmpty
                  ? _buildEstadoVazio(
                      icone: Icons.restaurant_rounded,
                      titulo: 'Sua próxima descoberta começa aqui',
                      mensagem: 'Cadastre o primeiro restaurante usando o botão Adicionar.',
                    )
                  : restaurantes.isEmpty
                  ? _buildEstadoVazio(
                      icone: Icons.search_off_rounded,
                      titulo: 'Nenhum resultado encontrado',
                      mensagem: 'Experimente outra busca ou selecione uma categoria diferente.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: restaurantes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildRestauranteCard(restaurantes[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRestauranteCard(Restaurant restaurante) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF292D34)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RestaurantDetailsScreen(restaurante: restaurante),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 110,
                  height: 112,
                  child: restaurante.fotoUrl.isNotEmpty
                      ? Image.network(
                          restaurante.fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagemPadrao();
                          },
                        )
                      : _buildImagemPadrao(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurante.categoria.isEmpty
                          ? 'Culinária variada'
                          : restaurante.categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: laranja,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      restaurante.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textoPrincipal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 19,
                          color: dourado,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurante.avaliacao.toStringAsFixed(1),
                          style: const TextStyle(
                            color: textoPrincipal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: textoSecundario,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            restaurante.endereco.isEmpty
                                ? 'Endereço não informado'
                                : restaurante.endereco,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textoSecundario,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: restaurante.isFavorito
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                onPressed: () async {
                  try {
                    await repository.atualizarFavorito(
                      restaurante.id,
                      !restaurante.isFavorito,
                    );
                  } catch (_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível atualizar o favorito.'),
                        backgroundColor: Color(0xFFB91C1C),
                      ),
                    );
                  }
                },
                icon: Icon(
                  restaurante.isFavorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: restaurante.isFavorito
                      ? const Color(0xFFFF5D73)
                      : textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagemPadrao() {
    return Container(
      color: const Color(0xFF252932),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_rounded, size: 34, color: laranja),
    );
  }

  Widget _buildEstadoVazio({
    required IconData icone,
    required String titulo,
    required String mensagem,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.25,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: laranja.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icone, size: 36, color: laranja),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textoPrincipal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textoSecundario,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaChip(String categoria) {
    final selecionada = categoriaSelecionada == categoria;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        label: Text(categoria),
        selected: selecionada,
        onSelected: (selecionar) {
          setState(() {
            categoriaSelecionada = categoria;
          });
        },
        selectedColor: laranja,
        backgroundColor: superficie,
        labelStyle: TextStyle(
          color: selecionada ? Colors.white : textoSecundario,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selecionada ? laranja : const Color(0xFF292D34),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
