class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnailUrl;
  final String publishedDate;
  final int? pageCount;
  bool isFavorite;

  Book({   
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedDate,
    this.pageCount,
    this.isFavorite = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    
    return Book(
      id: json['id'] as String,
      title: volumeInfo['title'] as String? ?? 'Sans titre',
      authors: volumeInfo['authors'] != null
          ? List<String>.from(volumeInfo['authors'])
          : ['Auteur inconnu'],
      description: volumeInfo['description'] as String? ?? 'Aucune description disponible',
      thumbnailUrl: imageLinks?['thumbnail'] as String? ?? '',
      publishedDate: volumeInfo['publishedDate'] as String? ?? 'Date inconnue',
      pageCount: volumeInfo['pageCount'] as int?,
    );
  }
}