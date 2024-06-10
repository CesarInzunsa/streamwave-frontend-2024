// Flutter Packages
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';

// Plugins
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// Controllers
import '../controller/controller.dart';
import '../model/movie_model.dart';
import '../model/user_model.dart';

class Home extends StatefulWidget {
  final UserModel user;
  const Home({super.key, required this.user});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
   String subscriptionPackage = '';

  @override
  void initState() {
    super.initState();

    // Obtener el paquete de suscripción del usuario
    subscriptionPackage = widget.user.subscriptionPackage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text(
          'StreamWave: v1',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.red[600],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 11),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/welcome', (route) => false);
              },
              child: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: _drawBody(),
    );
  }

  Widget _drawBody() {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.red),
          thickness: MaterialStateProperty.all(4.0),
        ),
      ),
      child: Scrollbar(
        //thumbVisibility: true,
        child: ListView(
          primary: true,
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Aquí ira la suscripción de peliculas
            _displaySectionTitle('Recientemente Agregado al Catalogo'),
            _displayMoviesSubscription(),

            // Aquí iran las peliculas de la categoría de drama
            _displayMoviesByCategory('Drama'),

            // Aquí iran las peliculas de la categoría de terror
            _displayMoviesByCategory('Terror'),

            // Aquí iran las peliculas de la categoría de Crimen
            _displayMoviesByCategory('Crimen'),

            // Aquí iran las peliculas de la categoría de comedia
            _displayMoviesByCategory('Comedia'),

            // Aquí iran las peliculas de la categoría de Accion
            _displayMoviesByCategory('Accion'),
          ],
        ),
      ),
    );
  }

  _getCarouselOptions() {
    return CarouselOptions(
      height: 200.0,
      aspectRatio: 2.0,
      autoPlayCurve: Curves.fastOutSlowIn,
      enableInfiniteScroll: true,
      viewportFraction: 0.3,
    );
  }

  Widget _displayMoviesByCategory(String category) {
    return FutureBuilder(
      future: Controller(context)
          .getMoviesByCategory(category, subscriptionPackage),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.data == null || snapshot.data.isEmpty) {
            log('no data');
            return const SizedBox.shrink();
          } else {
            log('data');
            return Column(
              children: [
                _displaySectionTitle(category),
                CarouselSlider(
                  options: _getCarouselOptions(),
                  items: snapshot.data.map<Widget>((movie) {
                    return Builder(
                      builder: (BuildContext context) {
                        return _getCarouselImages(movie);
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          }
        }
      },
    );
  }

  Widget _displayMoviesSubscription() {
    String subscriptionDocument = '''
        subscription BasicMovieAdded {
          movieAdded {
            id
            title
            description
            category
            subscriptionPackage
            imageUrl
            trailerUrl
            createdAt
          }
        }
  ''';

    return Subscription(
      options: SubscriptionOptions(
        document: gql(subscriptionDocument),
      ),
      builder: (result) {
        // Sí hay un error en la suscripción
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        // Sí la suscripción está cargando
        if (result.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Sí la suscripción no tiene datos
        if (result.data!.isEmpty) {
          return const Center(
            child: Text('No data found!'),
          );
        }

        // Sí la suscripción tiene datos
        return ResultAccumulator.appendUniqueEntries(
          latest: result.data!['movieAdded'],
          builder: (context, {results}) {
            return CarouselSlider(
              options: _getCarouselOptions(),
              items: results!.map((movie) {
                return Builder(
                  builder: (BuildContext context) {
                    return _getCarouselImages(MovieModel.fromJson(movie));
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  _getCarouselImages(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        // Aquí va el dialogo con la información y trailer de la película
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              surfaceTintColor: Colors.grey[900],
              backgroundColor: Colors.grey[900],
              shadowColor: Colors.grey[900],
              content: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                ),
                child: Column(
                  children: [
                    _displayMovieTrailer(movie.trailerUrl),
                    _displayMovieTitle(movie.title),
                    _displayMoviePlayButton(),
                    _displayMovieDownloadButton(),
                    _displayMovieDescription(movie.description),
                  ],
                ),
              ),
              actions: [
                _displayCloseButton(),
              ],
            );
          },
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Image.network(movie.imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _displayMovieTrailer(String trailerUrl) {
    return SizedBox(
      height: 300,
      width: 500,
      child: YoutubePlayer(
        controller: YoutubePlayerController.fromVideoId(
          autoPlay: true,
          videoId: trailerUrl,
        ),
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _displayMovieTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: 500,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _displayMoviePlayButton() {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: 500,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play'),
      ),
    );
  }

  Widget _displayMovieDownloadButton() {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: 500,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey[800],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        icon: const Icon(Icons.download),
        label: const Text('Descargar'),
      ),
    );
  }

  Widget _displayMovieDescription(String description) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: 500,
      child: Text(description, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _displayCloseButton() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _displaySectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, left: 10.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20.0),
          ),
        ],
      ),
    );
  }
}
