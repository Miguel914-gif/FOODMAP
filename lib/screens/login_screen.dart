import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool senhaVisivel = false;
  bool carregando = false;

  static const Color fundo = Color(0xFF0D0F12);
  static const Color superficie = Color(0xFF181B20);
  static const Color laranja = Color(0xFFFF6B35);
  static const Color texto = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9CA3AF);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => carregando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'invalid-email':
          mensagem = 'Digite um e-mail válido.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          mensagem = 'E-mail ou senha incorretos.';
          break;
        case 'too-many-requests':
          mensagem = 'Muitas tentativas. Tente novamente mais tarde.';
          break;
        case 'network-request-failed':
          mensagem = 'Verifique sua conexão com a internet.';
          break;
        default:
          mensagem = 'Não foi possível entrar. Tente novamente.';
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
          content: Text('Ocorreu um erro ao entrar. Tente novamente.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF30343D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: laranja, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: laranja.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: laranja,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'FOODMAP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(fontSize: 17, color: textoSecundario),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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

                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                        if (!regex.hasMatch(value.trim())) {
                          return 'Digite um e-mail válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: passwordController,
                      obscureText: !senhaVisivel,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: texto),
                      cursorColor: laranja,
                      onFieldSubmitted: (_) {
                        if (!carregando) _entrar();
                      },
                      decoration: _decoracao(
                        rotulo: 'Senha',
                        dica: 'Digite sua senha',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          onPressed: () {
                            setState(() => senhaVisivel = !senhaVisivel);
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
                          return 'Digite sua senha.';
                        }

                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A recuperação de senha será implementada '
                                'na próxima etapa.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: laranja),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: carregando ? null : _entrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: laranja,
                          foregroundColor: Colors.white,
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
                                'ENTRAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Ainda não tem uma conta?',
                          style: TextStyle(color: textoSecundario),
                        ),
                        TextButton(
                          onPressed: carregando
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Cadastre-se',
                            style: TextStyle(
                              color: laranja,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
