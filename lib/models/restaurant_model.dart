class Restaurant {
  final String id;
  final String nome;
  final String categoria;
  final double avaliacao;
  final String endereco;
  final String descricao;
  final bool isFavorito;
  final String fotoUrl;
  final String userId;

  const Restaurant({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.avaliacao,
    required this.endereco,
    required this.descricao,
    required this.isFavorito,
    required this.fotoUrl,
    required this.userId,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'avaliacao': avaliacao,
      'endereco': endereco,
      'descricao': descricao,
      'isFavorito': isFavorito,
      'fotoUrl': fotoUrl,
      'userId': userId,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      categoria: map['categoria'] ?? '',
      avaliacao: (map['avaliacao'] ?? 0).toDouble(),
      endereco: map['endereco'] ?? '',
      descricao: map['descricao'] ?? '',
      isFavorito: map['isFavorito'] ?? false,
      fotoUrl: map['fotoUrl'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}
