import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  bool carregando = false;

  static const Color fundo = Color(0xFF0D0F12);
  static const Color superficie = Color(0xFF181B20);
  static const Color laranja = Color(0xFFFF6B35);
  static const Color texto = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9CA3AF);
  static const Color borda = Color(0xFF30343D);

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

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => carregando = true);

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: senhaController.text,
          );

      // Guarda o nome informado no perfil do usuário do Firebase.
      await credencial.user?.updateDisplayName(nomeController.text.trim());

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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro ao criar a conta. Tente novamente.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
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
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: laranja.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 44,
                          color: laranja,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
                    const SizedBox(height: 32),

                    // Nome
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

                    // E-mail
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

                    // Senha
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

                    // Confirmar senha
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
