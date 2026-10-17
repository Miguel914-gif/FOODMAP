import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';

class RestaurantFormScreen extends StatefulWidget {
  final Restaurant? restaurante;

  const RestaurantFormScreen({super.key, this.restaurante});

  bool get modoEdicao => restaurante != null;

  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final enderecoController = TextEditingController();
  final descricaoController = TextEditingController();
  final fotoUrlController = TextEditingController();

  final RestaurantRepository _repository = RestaurantRepository();

  static const Color _fundo = Color(0xFF0D0F12);
  static const Color _card = Color(0xFF181B20);
  static const Color _laranja = Color(0xFFFF6B35);
  static const Color _texto = Color(0xFFF5F5F5);
  static const Color _textoSecundario = Color(0xFF9CA3AF);
  static const Color _borda = Color(0xFF30343D);

  String categoriaSelecionada = 'Brasileira';
  double avaliacao = 5.0;
  bool isFavorito = false;
  bool carregando = false;

  final List<String> categorias = [
    'Brasileira',
    'Italiana',
    'Japonesa',
    'Mexicana',
    'Árabe',
    'Hambúrguer',
    'Pizza',
    'Chinesa',
    'Vegetariana',
    'Outras',
  ];

  @override
  void initState() {
    super.initState();

    final restaurante = widget.restaurante;

    if (restaurante != null) {
      nomeController.text = restaurante.nome;
      enderecoController.text = restaurante.endereco;
      descricaoController.text = restaurante.descricao;
      fotoUrlController.text = restaurante.fotoUrl;
      categoriaSelecionada = restaurante.categoria;
      avaliacao = restaurante.avaliacao;
      isFavorito = restaurante.isFavorito;

      if (!categorias.contains(categoriaSelecionada)) {
        categorias.add(categoriaSelecionada);
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    enderecoController.dispose();
    descricaoController.dispose();
    fotoUrlController.dispose();
    super.dispose();
  }

  InputDecoration _decoracaoCampo({
    required String rotulo,
    String? dica,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      labelStyle: const TextStyle(color: _textoSecundario),
      floatingLabelStyle: const TextStyle(color: _laranja),
      hintStyle: const TextStyle(color: _textoSecundario),
      prefixIcon: Icon(icone, color: _laranja),
      filled: true,
      fillColor: _card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _laranja, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não encontrado. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      if (widget.modoEdicao) {
        final restauranteAtualizado = Restaurant(
          id: widget.restaurante!.id,
          nome: nomeController.text.trim(),
          categoria: categoriaSelecionada,
          avaliacao: avaliacao,
          endereco: enderecoController.text.trim(),
          descricao: descricaoController.text.trim(),
          isFavorito: isFavorito,
          fotoUrl: fotoUrlController.text.trim(),
          userId: widget.restaurante!.userId,
        );

        await _repository.atualizarRestaurante(restauranteAtualizado);
      } else {
        final restaurante = Restaurant(
          id: '',
          nome: nomeController.text.trim(),
          categoria: categoriaSelecionada,
          avaliacao: avaliacao,
          endereco: enderecoController.text.trim(),
          descricao: descricaoController.text.trim(),
          isFavorito: isFavorito,
          fotoUrl: fotoUrlController.text.trim(),
          userId: usuario.uid,
        );

        await _repository.criarRestaurante(restaurante);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.modoEdicao
                ? 'Restaurante atualizado com sucesso!'
                : 'Restaurante cadastrado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.modoEdicao
                ? 'Não foi possível atualizar o restaurante: $e'
                : 'Não foi possível cadastrar o restaurante: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.modoEdicao
        ? 'Editar restaurante'
        : 'Novo restaurante';

    final subtitulo = widget.modoEdicao
        ? 'Atualize os dados do restaurante.'
        : 'Preencha os dados do restaurante.';

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: _fundo,
        foregroundColor: _texto,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _texto,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 15, color: _textoSecundario),
                ),
                const SizedBox(height: 25),

                // NOME
                TextFormField(
                  controller: nomeController,
                  enabled: !carregando,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: _texto),
                  cursorColor: _laranja,
                  decoration: _decoracaoCampo(
                    rotulo: 'Nome do restaurante',
                    dica: 'Ex.: Sabor da Praça',
                    icone: Icons.restaurant,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o nome do restaurante.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // CATEGORIA
                DropdownButtonFormField<String>(
                  initialValue: categoriaSelecionada,
                  dropdownColor: _card,
                  style: const TextStyle(color: _texto, fontSize: 16),
                  iconEnabledColor: _laranja,
                  decoration: _decoracaoCampo(
                    rotulo: 'Categoria / Culinária',
                    icone: Icons.restaurant_menu,
                  ),
                  items: categorias.map((categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(
                        categoria,
                        style: const TextStyle(color: _texto),
                      ),
                    );
                  }).toList(),
                  onChanged: carregando
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              categoriaSelecionada = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 22),

                // AVALIAÇÃO
                const Text(
                  'Avaliação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _texto,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      final estrela = index + 1;

                      return IconButton(
                        tooltip: '$estrela estrela(s)',
                        onPressed: carregando
                            ? null
                            : () {
                                setState(() {
                                  avaliacao = estrela.toDouble();
                                });
                              },
                        icon: Icon(
                          estrela <= avaliacao ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC857),
                          size: 32,
                        ),
                      );
                    }),
                    Text(
                      avaliacao.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ENDEREÇO
                TextFormField(
                  controller: enderecoController,
                  enabled: !carregando,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  style: const TextStyle(color: _texto),
                  cursorColor: _laranja,
                  decoration: _decoracaoCampo(
                    rotulo: 'Endereço',
                    dica: 'Rua, número, bairro, cidade',
                    icone: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o endereço.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // DESCRIÇÃO
                TextFormField(
                  controller: descricaoController,
                  enabled: !carregando,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  style: const TextStyle(color: _texto),
                  cursorColor: _laranja,
                  decoration: _decoracaoCampo(
                    rotulo: 'Descrição',
                    dica: 'Descreva o restaurante...',
                    icone: Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite uma descrição.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // FOTO
                TextFormField(
                  controller: fotoUrlController,
                  enabled: !carregando,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: _texto),
                  cursorColor: _laranja,
                  decoration: _decoracaoCampo(
                    rotulo: 'URL da foto',
                    dica: 'https://...',
                    icone: Icons.image_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite a URL da foto.';
                    }

                    final url = Uri.tryParse(value.trim());

                    if (url == null ||
                        !url.hasScheme ||
                        !url.hasAuthority ||
                        !(url.scheme == 'http' || url.scheme == 'https')) {
                      return 'Digite uma URL válida começando com http:// ou https://.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // FAVORITO
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Adicionar aos favoritos',
                    style: TextStyle(color: _texto),
                  ),
                  subtitle: const Text(
                    'Marcar este restaurante como favorito',
                    style: TextStyle(color: _textoSecundario),
                  ),
                  value: isFavorito,
                  activeThumbColor: _laranja,
                  onChanged: carregando
                      ? null
                      : (value) {
                          setState(() {
                            isFavorito = value;
                          });
                        },
                ),
                const SizedBox(height: 20),

                // SALVAR
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: carregando ? null : _salvar,
                    icon: carregando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      carregando
                          ? 'SALVANDO...'
                          : widget.modoEdicao
                          ? 'SALVAR ALTERAÇÕES'
                          : 'SALVAR RESTAURANTE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _laranja,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _laranja.withValues(alpha: 0.5),
                      elevation: 0,
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
        ),
      ),
    );
  }
}
