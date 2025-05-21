import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/book.dart';
import 'services/database_service.dart';
import 'services/database_test.dart';

// Global list to store favorites during the session
List<Book> favoritesBooks = [];

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch any errors during app initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  // Custom error widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.exception.toString(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Try to restart the app
                runApp(const MyApp());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  };
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF6F00),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Force rebuild when switching tabs
          if (index == 1) {
            // Switching to favorites tab
            setState(() {
              // Rebuild the favorites screen
              _screens[1] = const FavoritesScreen();
            });
          } else if (index == 0 && _currentIndex == 1) {
            // Switching back to search tab from favorites
            setState(() {
              // Rebuild the search screen
              _screens[0] = const SearchScreen();
            });
          }
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
        ],
      ),
    );
  }
}

class BookService {
  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final response = await http.get(Uri.parse('$baseUrl?q=${Uri.encodeComponent(query)}'));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'] as List<dynamic>?;
        
        if (items == null) return [];
        
        final List<Book> books = [];
        for (var item in items) {
          try {
            final book = Book.fromJson(item);
            if (book.thumbnailUrl.isNotEmpty) {
              // Check if book is in favorites
              book.isFavorite = favoritesBooks.any((favBook) => favBook.id == book.id);
              books.add(book);
            }
          } catch (e) {
            print('Error parsing book: $e');
          }
        }
         
        return books;
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error searching books: $e');
      throw Exception('Error searching books: $e');
    }
  } 
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BookService _bookService = BookService();
  
  List<Book> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _performSearch('flutter');
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un terme de recherche';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      print('SearchScreen: Searching for "$query"');
      final books = await _bookService.searchBooks(query);
      if (!mounted) return;
      
      // Check favorite status for each book
      for (var book in books) {
        book.isFavorite = favoritesBooks.any((favBook) => favBook.id == book.id);
      }
      
      setState(() {
        _searchResults = books;
        _isLoading = false;
        if (books.isEmpty && _hasSearched) {
          _errorMessage = 'Aucun résultat trouvé pour "$query"';
        }
      });
      print('SearchScreen: Found ${books.length} results for "$query"');
    } catch (e) {
      print('SearchScreen: Error searching books: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors de la recherche: $e';
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  void _toggleFavorite(Book book) {
    setState(() {
      book.isFavorite = !book.isFavorite;
    });
    
    if (book.isFavorite) {
      print('SearchScreen: Adding book to favorites: ${book.id}');
      // Add to favorites if not already there
      if (!favoritesBooks.any((favBook) => favBook.id == book.id)) {
        favoritesBooks.add(book);
      }
    } else {
      print('SearchScreen: Removing book from favorites: ${book.id}');
      // Remove from favorites
      favoritesBooks.removeWhere((favBook) => favBook.id == book.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recherche de Livres',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un livre...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                onSubmitted: (query) => _performSearch(query),
              ),
            ],
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : _searchResults.isEmpty && _hasSearched
                ? const Expanded(
                    child: Center(
                      child: Text('Aucun résultat trouvé'),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final book = _searchResults[index];
                        return BookListItem(
                          book: book,
                          onFavoriteToggle: () => _toggleFavorite(book),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _errorMessage = '';
  List<Book> _localFavorites = [];
  
  @override
  void initState() {
    super.initState();
    _refreshLocalFavorites();
  }
  
  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when widget updates
    _refreshLocalFavorites();
  }
  
  void _refreshLocalFavorites() {
    setState(() {
      // Create a new list from the global favorites
      _localFavorites = List.from(favoritesBooks);
    });
  }

  void _toggleFavorite(Book book) {
    setState(() {
      book.isFavorite = !book.isFavorite;
      
      if (!book.isFavorite) {
        // Remove from favorites
        _localFavorites.removeWhere((favBook) => favBook.id == book.id);
        favoritesBooks.removeWhere((favBook) => favBook.id == book.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always refresh local favorites when building
    _refreshLocalFavorites();
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.secondary,
          child: const Text(
            'Mes Favoris',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _localFavorites.isEmpty
          ? const Expanded(
              child: Center(
                child: Text('Aucun livre favori'),
              ),
            )
          : Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _localFavorites.length,
                itemBuilder: (context, index) {
                  final book = _localFavorites[index];
                  return BookListItem(
                    book: book,
                    onFavoriteToggle: () => _toggleFavorite(book),
                  );
                },
              ),
            ),
      ],
    );
  }
}

class BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onFavoriteToggle;

  const BookListItem({
    super.key,
    required this.book,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              clipBehavior: Clip.hardEdge,
              child: book.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      book.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.book,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authors.join(', '),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${book.publishedDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (book.pageCount != null)
                    Text(
                      'Pages: ${book.pageCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Favorite button
            IconButton(
              icon: Icon(
                book.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: book.isFavorite ? Colors.red : null,
              ),
              onPressed: onFavoriteToggle,
            ),
          ],
        ),
      ),
    );
  }
}
