import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final ImagePicker seletorImagem = ImagePicker();

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  bool carregando = false;

  int avatarSelecionado = 0;
  Uint8List? fotoSelecionada;

  static const Color fundo = Color(0xFF0D0F12);
  static const Color superficie = Color(0xFF181B20);
  static const Color laranja = Color(0xFFFF6B35);
  static const Color texto = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9CA3AF);
  static const Color borda = Color(0xFF30343D);

  final List<IconData> avatares = const [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.restaurant_rounded,
    Icons.emoji_emotions_rounded,
    Icons.lunch_dining_rounded,
    Icons.local_pizza_rounded,
  ];

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  InputDecoration _decoracao({
    required String rotulo,
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      prefixIcon: Icon(icone, color: laranja),
      suffixIcon: sufixo,
      filled: true,
      fillColor: superficie,
      labelStyle: const TextStyle(color: textoSecundario),
      hintStyle: const TextStyle(color: textoSecundario),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: laranja, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFF5252)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
      ),
    );
  }

  // Seleciona uma foto do computador ou dispositivo.
  Future<void> _selecionarFoto() async {
    try {
      final XFile? imagem = await seletorImagem.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 60,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      // Limite preventivo para não enviar uma imagem muito grande.
      if (bytes.length > 300 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A imagem ficou grande demais. Escolha uma foto menor.',
            ),
          ),
        );
        return;
      }

      setState(() {
        fotoSelecionada = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    }
  }

  // Remove a foto e volta a utilizar o avatar escolhido.
  void _removerFoto() {
    setState(() {
      fotoSelecionada = null;
    });
  }

  // Mostra a foto escolhida ou o avatar padrão.
  Widget _construirFotoPerfil({
    required double tamanho,
    required double tamanhoIcone,
  }) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: laranja.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: laranja, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: fotoSelecionada != null
          ? Image.memory(
              fotoSelecionada!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  avatares[avatarSelecionado],
                  size: tamanhoIcone,
                  color: laranja,
                );
              },
            )
          : Icon(
              avatares[avatarSelecionado],
              size: tamanhoIcone,
              color: laranja,
            ),
    );
  }

  Widget _construirSeletorFoto() {
    return Column(
      children: [
        Stack(
          children: [
            _construirFotoPerfil(tamanho: 110, tamanhoIcone: 54),
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Escolher foto',
                onPressed: carregando ? null : _selecionarFoto,
                style: IconButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.camera_alt_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: carregando
              ? null
              : fotoSelecionada == null
              ? _selecionarFoto
              : _removerFoto,
          icon: Icon(
            fotoSelecionada == null
                ? Icons.add_a_photo_outlined
                : Icons.delete_outline,
          ),
          label: Text(
            fotoSelecionada == null
                ? 'Adicionar foto de perfil'
                : 'Remover foto',
          ),
          style: TextButton.styleFrom(foregroundColor: laranja),
        ),
      ],
    );
  }

  Future<void> _cadastrar() async {
    if (carregando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => carregando = true);

    User? usuarioCriado;

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: senhaController.text,
          );

      usuarioCriado = credencial.user;

      if (usuarioCriado == null) {
        throw Exception('Não foi possível obter o usuário criado.');
      }

      final nome = nomeController.text.trim();

      await usuarioCriado.updateDisplayName(nome);

      // Converte a imagem para Base64 antes de salvar no Firestore.
      final String? fotoBase64 = fotoSelecionada != null
          ? base64Encode(fotoSelecionada!)
          : null;

      // Salva os dados do perfil na coleção "users".
      await FirebaseFirestore.instance
          .collection('users')
          .doc(usuarioCriado.uid)
          .set({
            'nome': nome,
            'email': emailController.text.trim(),
            'avatarIndex': avatarSelecionado,
            'fotoBase64': fotoBase64,
            'criadoEm': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este e-mail já está cadastrado.';
          break;
        case 'invalid-email':
          mensagem = 'Digite um e-mail válido.';
          break;
        case 'weak-password':
          mensagem = 'A senha é muito fraca.';
          break;
        case 'network-request-failed':
          mensagem = 'Verifique sua conexão com a internet.';
          break;
        case 'operation-not-allowed':
          mensagem = 'O cadastro por e-mail está desativado no Firebase.';
          break;
        default:
          mensagem = 'Não foi possível criar a conta. Tente novamente.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usuarioCriado != null
                ? 'A conta foi criada, mas houve um erro ao salvar o perfil. '
                      'Confira as regras e o tamanho da imagem. Detalhe: $e'
                : 'Ocorreu um erro ao criar a conta. Detalhe: $e',
          ),
          backgroundColor: const Color(0xFFB91C1C),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  Widget _seletorAvatares() {
    return Column(
      children: [
        const Text(
          'Ou escolha um avatar',
          style: TextStyle(
            color: texto,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(avatares.length, (index) {
            final selecionado = avatarSelecionado == index;

            return InkWell(
              onTap: carregando
                  ? null
                  : () {
                      setState(() {
                        avatarSelecionado = index;
                      });
                    },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: selecionado
                      ? laranja.withValues(alpha: 0.2)
                      : superficie,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selecionado ? laranja : borda,
                    width: selecionado ? 2.5 : 1,
                  ),
                ),
                child: Icon(
                  avatares[index],
                  color: selecionado ? laranja : textoSecundario,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: fundo,
        foregroundColor: texto,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _construirSeletorFoto()),
                    const SizedBox(height: 12),
                    const Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre-se para descobrir e organizar '
                      'seus restaurantes favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _seletorAvatares(),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: nomeController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: texto),
                      cursorColor: laranja,
                      decoration: _decoracao(
                        rotulo: 'Nome',
                        dica: 'Digite seu nome',
                        icone: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite seu nome.';
                        }
                        if (value.trim().length < 3) {
                          return 'Digite pelo menos 3 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: const TextStyle(color: texto),
                      cursorColor: laranja,
                      decoration: _decoracao(
                        rotulo: 'E-mail',
                        dica: 'Digite seu e-mail',
                        icone: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite seu e-mail.';
                        }

                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Digite um e-mail válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: senhaController,
                      obscureText: !senhaVisivel,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: texto),
                      cursorColor: laranja,
                      decoration: _decoracao(
                        rotulo: 'Senha',
                        dica: 'Crie uma senha com pelo menos 6 caracteres',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          tooltip: senhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: () {
                            setState(() {
                              senhaVisivel = !senhaVisivel;
                            });
                          },
                          icon: Icon(
                            senhaVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: textoSecundario,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite uma senha.';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: confirmarSenhaController,
                      obscureText: !confirmarSenhaVisivel,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: texto),
                      cursorColor: laranja,
                      onFieldSubmitted: (_) {
                        if (!carregando) _cadastrar();
                      },
                      decoration: _decoracao(
                        rotulo: 'Confirmar senha',
                        dica: 'Digite a senha novamente',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          tooltip: confirmarSenhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: () {
                            setState(() {
                              confirmarSenhaVisivel = !confirmarSenhaVisivel;
                            });
                          },
                          icon: Icon(
                            confirmarSenhaVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: textoSecundario,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha.';
                        }
                        if (value != senhaController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: carregando ? null : _cadastrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: laranja,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: laranja.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: carregando
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CRIAR CONTA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: carregando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Já tenho uma conta',
                        style: TextStyle(
                          color: laranja,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
