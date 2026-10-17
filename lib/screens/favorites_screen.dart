import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';
import 'restaurant_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final repository = RestaurantRepository();

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Favoritos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: repository.listarRestaurantes(usuario.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar os favoritos.'),
            );
          }

          final favoritos = (snapshot.data ?? [])
              .where((restaurante) => restaurante.isFavorito)
              .toList();

          if (favoritos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 70,
                      color: Color(0xFFF97316),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Você ainda não tem favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292524),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toque no coração de um restaurante para salvá-lo aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF78716C)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favoritos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final restaurante = favoritos[index];

              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFFFF7ED),
                      child: restaurante.fotoUrl.isNotEmpty
                          ? Image.network(
                              restaurante.fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.restaurant,
                                  color: Color(0xFFF97316),
                                );
                              },
                            )
                          : const Icon(
                              Icons.restaurant,
                              color: Color(0xFFF97316),
                            ),
                    ),
                  ),
                  title: Text(
                    restaurante.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292524),
                    ),
                  ),
                  subtitle: Text(
                    '${restaurante.categoria} • '
                    '⭐ ${restaurante.avaliacao.toStringAsFixed(1)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover dos favoritos',
                    onPressed: () async {
                      try {
                        await repository.atualizarFavorito(
                          restaurante.id,
                          false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível remover dos favoritos.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.favorite, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantDetailsScreen(restaurante: restaurante),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
