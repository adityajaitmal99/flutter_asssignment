import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MovieSearchProvider(),
      child: MovieSearchApp(),
    ),
  );
}

class MovieSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Search',
      home: MovieSearchScreen(),
    );
  }
}

class MovieSearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MovieSearchProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light Gray background
      appBar: AppBar(
        title: const Text('  Home'),
        centerTitle: false,  // Left-align the title
        backgroundColor: const Color(0xFFF5F5F5), // Match the background color
        elevation: 0, // Remove the shadow
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Square Search Box
            TextField(
              controller: provider.searchController,
              onSubmitted: provider.fetchMovies,
              decoration: InputDecoration(
                hintText: 'Search for movies...',
                hintStyle: const TextStyle(color: Color(0xFF212121)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF212121)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0.0), // Square corners
                ),
                filled: true,
                fillColor: Colors.white, // White search box background
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.errorMessage.isNotEmpty)
              Center(
                child: Text(
                  provider.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
            // Movie List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.movies.length,
                  itemBuilder: (context, index) {
                    final movie = provider.movies[index];
                    return MovieCard(
                      title: movie['title'] ?? 'No Title',
                      genre: movie['release_date'] ?? 'Unknown',
                      rating: movie['vote_average']?.toString() ?? 'N/A',
                      posterPath: movie['poster_path'],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final String title;
  final String genre;
  final String rating;
  final String? posterPath;

  const MovieCard({
    required this.title,
    required this.genre,
    required this.rating,
    this.posterPath,
  });

  // Function to randomly assign color for the rating badge
  Color _getRandomColor() {
    final colors = [const Color(0xFF5EC570), const Color(0xFF1C7EEB)]; // Green and Blue
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/150';

    return Card(
      elevation: 5, // Add more shadow for a floating effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Curved edges for the card
      color: Colors.white, // White background for the card
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners for the poster
              child: Image.network(
                posterUrl,
                height: 150,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Movie Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Genre or Release Date
                    Text(
                      genre,
                      style: const TextStyle(
                        color: Color(0xFF212121), // Dark Gray
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating badge
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _getRandomColor(),
                            borderRadius: BorderRadius.circular(16.0), // Curved rating badge
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          child: Text(
                            '$rating IMDb',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MovieSearchProvider for State Management
class MovieSearchProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get movies => _movies;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  final String _apiKey = '421320142d71e6df6290884a1f6b23f2';

  // Fetch movies from the API
  Future<void> fetchMovies(String query) async {
    if (query.isEmpty) {
      _errorMessage = 'Please enter a search term.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.parse(
          'https://api.themoviedb.org/3/search/movie?api_key=$_apiKey&query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null) {
          _movies = data['results'];
        } else {
          _errorMessage = 'No movies found.';
        }
      } else {
        _errorMessage = 'Error fetching data: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
