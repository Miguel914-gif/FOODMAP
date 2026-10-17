import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_model.dart';

class RestaurantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'restaurants';

  // CREATE
  Future<void> criarRestaurante(Restaurant restaurante) async {
    final document = _firestore.collection(_collection).doc();

    final restauranteComId = Restaurant(
      id: document.id,
      nome: restaurante.nome,
      categoria: restaurante.categoria,
      avaliacao: restaurante.avaliacao,
      endereco: restaurante.endereco,
      descricao: restaurante.descricao,
      isFavorito: restaurante.isFavorito,
      fotoUrl: restaurante.fotoUrl,
      userId: restaurante.userId,
    );

    await document.set(restauranteComId.toMap());
  }

  // READ - todos os restaurantes do usuário
  Stream<List<Restaurant>> listarRestaurantes(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Restaurant.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // READ - restaurante por ID
  Future<Restaurant?> buscarPorId(String id) async {
    final document = await _firestore.collection(_collection).doc(id).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return Restaurant.fromMap({...document.data()!, 'id': document.id});
  }

  // UPDATE - atualizar restaurante
  Future<void> atualizarRestaurante(Restaurant restaurante) async {
    await _firestore
        .collection(_collection)
        .doc(restaurante.id)
        .update(restaurante.toMap());
  }

  // UPDATE - atualizar favorito
  Future<void> atualizarFavorito(String id, bool isFavorito) async {
    await _firestore.collection(_collection).doc(id).update({
      'isFavorito': isFavorito,
    });
  }

  // DELETE
  Future<void> excluirRestaurante(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
