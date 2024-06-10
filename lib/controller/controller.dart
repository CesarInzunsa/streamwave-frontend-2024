// Flutter packages
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';

// firebase
import 'package:firebase_storage/firebase_storage.dart';

// Plugins
import 'package:graphql_flutter/graphql_flutter.dart';

// Models
import '../model/movie_model.dart';
import '../model/user_model.dart';

class Controller {
  BuildContext context;

  Controller(this.context);

  /// Retorna una lista de usuarios
  Future<List<UserModel>> getAllUsers() async {
    List<UserModel> users = [];

    String getAllUsers = """
        query GetAllUsers {
          getAllUsers {
            id
            name
            email
            password
            subscriptionPackage
            createdAt
            type
          }
        }
    """;

    final QueryOptions options = QueryOptions(
      document: gql(getAllUsers),
    );

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final QueryResult result = await client.query(options);

    if (result.hasException) {
      //print(result.exception.toString());
      return [];
    }

    final List<dynamic> data = result.data?['getAllUsers'] ?? [];

    for (var i = 0; i < data.length; i++) {
      UserModel user = UserModel.fromJson(data[i]);

      DateTime utcTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(user.createdAt));
      DateTime localTime = utcTime.toLocal();

      user.createdAt = localTime.toString().substring(0, 19);

      users.add(user);
    }

    return users;
  }

  /// Retorna una lista de peliculas
  ///
  /// [subscriptionPackage] es el paquete de suscripción del usuario.
  Future<List<MovieModel>> getAllMovies(String subscriptionPackage) async {
    List<MovieModel> movies = [];

    String getAllMovies = """
        query GetAllMoviesBySubscription(\$subscriptionPackage: String!) {
          getAllMoviesBySubscription(subscriptionPackage: \$subscriptionPackage) {
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
    """;

    final QueryOptions options = QueryOptions(
      document: gql(getAllMovies),
      variables: {
        'subscriptionPackage': subscriptionPackage,
      },
    );

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final QueryResult result = await client.query(options);

    if (result.hasException) {
      //print(result.exception.toString());
      return [];
    }

    final List<dynamic> data = result.data?['getAllMoviesBySubscription'] ?? [];

    for (var i = 0; i < data.length; i++) {
      MovieModel movie = MovieModel.fromJson(data[i]);

      DateTime utcTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(movie.createdAt));
      DateTime localTime = utcTime.toLocal();

      movie.createdAt = localTime.toString().substring(0, 19);

      movies.add(movie);
    }

    return movies;
  }

  /// Retorna una lista de peliculas por categoria
  ///
  /// [category] es una cadena que contiene la categoría de las películas a buscar
  /// [subscriptionPackage] es el paquete de suscripción del usuario.
  Future<List<MovieModel>> getMoviesByCategory(
    String category,
    String subscriptionPackage,
  ) async {
    List<MovieModel> movies = [];

    String getAllMovies = """
        query GetMoviesByCategory(\$category: String!, \$subscriptionPackage: String!) {
          getMoviesByCategory(category: \$category, subscriptionPackage: \$subscriptionPackage) {
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
    """;

    final QueryOptions options = QueryOptions(
      document: gql(getAllMovies),
      variables: {
        'category': category,
        'subscriptionPackage': subscriptionPackage,
      },
    );

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final QueryResult result = await client.query(options);

    if (result.hasException) {
      //print(result.exception.toString());
      return [];
    }

    final List<dynamic> data = result.data?['getMoviesByCategory'] ?? [];

    for (var i = 0; i < data.length; i++) {
      movies.add(MovieModel.fromJson(data[i]));
    }

    return movies;
  }

  /// Crea una nueva película
  ///
  /// [movie] es un objeto de tipo MovieModel que contiene la información de la película a crear.
  Future<bool> createMovie(MovieModel movie, File img) async {
    try {
      // Query para crear una nueva película
      String query = """
        mutation CreateMovie(
          \$title: String!
          \$description: String!
          \$category: String!
          \$subscriptionPackage: String!
          \$imageUrl: String!
          \$trailerUrl: String!
        ) {
          createMovie(
            title: \$title
            description: \$description
            category: \$category
            subscriptionPackage: \$subscriptionPackage
            imageUrl: \$imageUrl
            trailerUrl: \$trailerUrl
          )
        }
      """;

      // Crear conexion con firebase
      var carpetaRemota = FirebaseStorage.instance;
      log('1');

      // Crear una referencia a la carpeta remota
      var imgRef = carpetaRemota.ref('imgs/${DateTime.now()}.jpg');

      log('2');

      log(img.path);

      // Convertir blob a file
      // Subir la imagen
      //await imgRef.putData(img, SettableMetadata(contentType: 'image/jpeg'),);
      await imgRef.putFile(img);

      log('3');

      // Obtener y retonar la url de la imagen
      movie.imageUrl = await imgRef.getDownloadURL();

      log('4');

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'title': movie.title,
          'description': movie.description,
          'category': movie.category,
          'subscriptionPackage': movie.subscriptionPackage,
          'imageUrl': movie.imageUrl,
          'trailerUrl': movie.trailerUrl,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  /// Crea un nuevo usuario
  ///
  /// [user] es un objeto de tipo UserModel que contiene la información del usuario a crear.
  Future<bool> createUser(UserModel user) async {
    try {
      // Query para crear un nuevo usuario
      String query = """
        mutation CreateUser(
          \$name: String!
          \$email: String!
          \$password: String!
          \$type: String!
          \$subscriptionPackage: String!
        ) {
          createUser(
            name: \$name
            email: \$email
            password: \$password
            type: \$type
            subscriptionPackage: \$subscriptionPackage
          )
        }
      """;

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'name': user.name,
          'email': user.email,
          'password': user.password,
          'type': user.type,
          'subscriptionPackage': user.subscriptionPackage,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      if(result.data?['createUser'] == 'El email ya está en uso') {
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      // Query para actualizar un usuario
      String query = """
        mutation UpdateUser(
          \$updateUserId: ID!
          \$name: String!
          \$email: String!
          \$password: String!
          \$subscriptionPackage: String!
        ) {
          updateUser(
            id: \$updateUserId
            name: \$name
            email: \$email
            password: \$password
            subscriptionPackage: \$subscriptionPackage
          )
        }
      """;

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'updateUserId': user.id,
          'name': user.name,
          'email': user.email,
          'password': user.password,
          'subscriptionPackage': user.subscriptionPackage,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateMovie(MovieModel movie) async {
    try {
      // Query para actualizar una película
      String query = """
        mutation UpdateMovie(
          \$updateMovieId: ID!
          \$title: String!
          \$description: String!
          \$category: String!
          \$subscriptionPackage: String!
          \$imageUrl: String!
          \$trailerUrl: String!
        ) {
          updateMovie(
            id: \$updateMovieId
            title: \$title
            description: \$description
            category: \$category
            subscriptionPackage: \$subscriptionPackage
            imageUrl: \$imageUrl
            trailerUrl: \$trailerUrl
          )
        }
      """;

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'updateMovieId': movie.id,
          'title': movie.title,
          'description': movie.description,
          'category': movie.category,
          'subscriptionPackage': movie.subscriptionPackage,
          'imageUrl': movie.imageUrl,
          'trailerUrl': movie.trailerUrl,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMovie(MovieModel movie) async {
    try {
      // Query para eliminar una película
      String query = """
        mutation DeleteMovie(\$deleteMovieId: ID!) {
          deleteMovie(id: \$deleteMovieId)
        }
      """;

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'deleteMovieId': movie.id,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteUser(UserModel user) async {
    try {
      // Query para eliminar un usuario
      String query = """
        mutation DeleteUser(\$deleteUserId: ID!) {
          deleteUser(id: \$deleteUserId)
        }
      """;

      // Opciones de la mutacion
      final MutationOptions mutationOptions = MutationOptions(
        document: gql(query),
        variables: {
          'deleteUserId': user.id,
        },
      );

      // Cliente GraphQL
      final GraphQLClient client = GraphQLProvider.of(context).value;

      // Realizar la mutacion
      final QueryResult result = await client.mutate(mutationOptions);

      // Si hay un error, muestra el error por consola y retorna un false
      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return false;
      }

      // Si no hay error, retorna un true.
      return true;
    } catch (e) {
      // Si hay un error, retorna un false y muestra el error
      log('Error: ${e.toString()}');
      return false;
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      String query = """
        mutation Login(\$email: String!, \$password: String!) {
          login(email: \$email, password: \$password) {
            ... on User {
              id
              name
              email
              password
              subscriptionPackage
              type
              createdAt
            }
            ... on LoginError {
              success
              message
            }
          }
        }
      """;

      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {
          'email': email,
          'password': password,
        },
      );

      final GraphQLClient client = GraphQLProvider.of(context).value;

      final QueryResult result = await client.query(options);

      if (result.hasException) {
        log('Exception: ${result.exception.toString()}');
        return UserModel.empty();
      }

      // Si el usuario existe retonarlo
      if(result.data?['login']?['id'] != null) {
        final UserModel user = UserModel.fromJson(result.data?['login']);
        return user;
      }else{
        return UserModel.fromJson(result.data?['login']);
      }
    } catch (e) {
      log('Error: ${e.toString()}');
      return UserModel.empty();
    }
  }
}
