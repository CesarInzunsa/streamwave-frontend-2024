// Flutter Packages
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

// Plugins
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:image_picker/image_picker.dart';

// Controllers
import '../controller/controller.dart';
import '../model/movie_model.dart';
import '../model/user_model.dart';
import 'share/share.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final subscriptionPackage = 'PREMIUM';
  PageController pageController = PageController();
  SideMenuController sideMenu = SideMenuController();

  // llave del formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para peliculas
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _categoryController =
      TextEditingController(text: 'Accion');
  TextEditingController _subscriptionPackageController =
      TextEditingController(text: 'BASICO');
  TextEditingController _imageUrlController = TextEditingController();
  TextEditingController _trailerUrlController = TextEditingController();

  // Controladores para usuarios
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _typeController = TextEditingController(text: 'USER');

  // Lista de items para el dropdown
  List<DropdownMenuItem> typeitems = const [
    DropdownMenuItem(
      value: 'USER',
      child: Text('USER'),
    ),
    DropdownMenuItem(
      value: 'ADMIN',
      child: Text('ADMIN'),
    ),
  ];

  // Lista de items para el dropdown
  List<DropdownMenuItem> subscriptionPackageitems = const [
    DropdownMenuItem(
      value: 'BASICO',
      child: Text('BASICO'),
    ),
    DropdownMenuItem(
      value: 'ESTANDAR',
      child: Text('ESTANDAR'),
    ),
    DropdownMenuItem(
      value: 'PREMIUM',
      child: Text('PREMIUM'),
    ),
  ];

  // Lista de items para el dropdown
  List<DropdownMenuItem> categoryitems = const [
    DropdownMenuItem(
      value: 'Accion',
      child: Text('Accion'),
    ),
    DropdownMenuItem(
      value: 'Comedia',
      child: Text('Comedia'),
    ),
    DropdownMenuItem(
      value: 'Drama',
      child: Text('Drama'),
    ),
    DropdownMenuItem(
      value: 'Terror',
      child: Text('Terror'),
    ),
  ];

  // Lista para guardar todas las peliculas obtenidas del getall
  List<MovieModel> movies = [];
  List<MovieModel> moviesSubscriptions = [];

  // Lista para guardar todos los usuarios obtenidos del getall
  List<UserModel> users = [];
  List<UserModel> usersSubscriptions = [];

  // seleccionar una imagen
  File blob = File('');

  @override
  void initState() {
    // Connect SideMenuController and PageController together
    sideMenu.addListener((index) {
      pageController.jumpToPage(index);
    });
    super.initState();
  }

  Future<void> _fetchMovies() async {
    List<MovieModel> movies =
        await Controller(context).getAllMovies(subscriptionPackage);

    setState(() {
      this.movies = movies;
    });
  }

  Future<void> _fetchUsers() async {
    List<UserModel> users = await Controller(context).getAllUsers();

    setState(() {
      this.users = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Panel de Control'),
        leading: const Icon(Icons.movie_filter_outlined),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 11),
            child: ElevatedButton.icon(
              onPressed: _showCreateMovieDialog,
              label: const Text('Crear Pelicula'),
              icon: const Icon(Icons.movie_creation_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 11),
            child: ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              label: const Text('Crear Usuario'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ),
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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // SideMenu
          SideMenu(
            // Page controller to manage a PageView
            controller: sideMenu,
            // Will shows on top of all items, it can be a logo or a Title text
            //title: const Text('Panel de Control'),
            // Will show on bottom of SideMenu when displayMode was SideMenuDisplayMode.open
            //footer: const Text('demo'),
            // Notify when display mode changed
            onDisplayModeChanged: (mode) {
              //log(mode.toString());
            },
            // List of SideMenuItem to show them on SideMenu
            items: Share.getDesktopDestinations(sideMenu),
          ),
          // Contenido principal
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                _home(),
                _view(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _displayMoviesSubscription()),
        Expanded(child: _displayUsersSubscription()),
      ],
    );
  }

  Widget _view() {
    return Row(
      children: [
        Expanded(
          child: _displayAllMovies(),
        ),
        Expanded(
          child: _displayAllUsers(),
        ),
      ],
    );
  }

  Widget _displayMoviesSubscription() {
    String subscriptionDocument = '''
        subscription MovieAdded {
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
          return const Center(child: CircularProgressIndicator());
        }

        // Sí la suscripción no tiene datos
        if (result.data!.isEmpty) {
          return const Center(
            child: Text('No data found!'),
          );
        }

        // Extraer y convertir la data de la suscripción a MovieModel
        List<MovieModel> movies = [];
        movies.add(MovieModel.fromJson(result.data!['movieAdded']));

        // convertir la fecha de creación a un formato más legible
        for (MovieModel movie in movies) {
          DateTime utcTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(movie.createdAt),
          );
          DateTime localTime = utcTime.toLocal();
          movie.createdAt = localTime.toString().substring(0, 19);
        }

        // Sí la suscripción tiene datos
        this.moviesSubscriptions = movies;

        // Sí la suscripción tiene datos
        return ListView.builder(
          itemCount: moviesSubscriptions.length,
          itemBuilder: (BuildContext context, index) {
            return ListTile(
              title: Text(moviesSubscriptions[index].title),
              subtitle: Text(moviesSubscriptions[index].description),
              onTap: () {
                _showMovieDialog(context, moviesSubscriptions[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _displayUsersSubscription() {
    String subscriptionDocument = '''
        subscription UserAdded {
          userAdded {
            id
            name
            email
            password
            subscriptionPackage
            createdAt
            type
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

        // Extraer y convertir la data de la suscripción a UserModel
        List<UserModel> users = [];
        users.add(UserModel.fromJson(result.data!['userAdded']));

        // convertir la fecha de creación a un formato más legible
        for (UserModel user in users) {
          DateTime utcTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(user.createdAt),
          );
          DateTime localTime = utcTime.toLocal();
          user.createdAt = localTime.toString().substring(0, 19);
        }

        // Sí la suscripción tiene datos
        this.usersSubscriptions = users;

        // Sí la suscripción tiene datos
        return ListView.builder(
          itemCount: usersSubscriptions.length,
          itemBuilder: (BuildContext context, index) {
            return ListTile(
              title: Text(usersSubscriptions[index].name),
              subtitle: Text(usersSubscriptions[index].email),
              onTap: () {
                _showUserDialog(context, usersSubscriptions[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _displayAllMovies() {
    if (movies.isEmpty) {
      _fetchMovies();
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(movies[index].title),
          subtitle: Text(movies[index].description),
          onTap: () {
            _showMovieDialog(context, movies[index]);
          },
        );
      },
    );
  }

  Widget _displayAllUsers() {
    if (users.isEmpty) {
      _fetchUsers();
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(users[index].name),
          subtitle: Text(users[index].email),
          onTap: () {
            _showUserDialog(context, users[index]);
          },
        );
      },
    );
  }

  // Dialogo para mostrar los detalles de un usuario
  void _showUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${user.email}'),
              Text('Paquete: ${user.subscriptionPackage}'),
              Text('Tipo de usuario: ${user.type}'),
              Text('Fecha de creacion: ${user.createdAt}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmDeleteUserDialog(user);
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                _nameController.text = user.name;
                _emailController.text = user.email;
                _passwordController.text = user.password;
                _subscriptionPackageController.text = user.subscriptionPackage;
                _typeController.text = user.type;
                Navigator.of(context).pop();
                _showUpdateUserDialog(user);
              },
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Dialogo para mostrar los detalles de una película
  void _showMovieDialog(BuildContext context, MovieModel movie) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(movie.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Text('Descripcion: ${movie.description}'),
              ),
              Text('Categoria: ${movie.category}'),
              Text('Paquete: ${movie.subscriptionPackage}'),
              Text('Fecha de creacion: ${movie.createdAt}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmDeleteMovieDialog(movie);
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                _titleController.text = movie.title;
                _descriptionController.text = movie.description;
                _categoryController.text = movie.category;
                _subscriptionPackageController.text = movie.subscriptionPackage;
                _imageUrlController.text = movie.imageUrl;
                _trailerUrlController.text = movie.trailerUrl;
                Navigator.of(context).pop();
                _showUpdateMovieDialog(movie);
              },
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteMovieDialog(MovieModel movie) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Pelicula'),
          content:
              const Text('¿Estas seguro de que deseas eliminar esta pelicula?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMovie(movie);
              },
              child: const Text('Si'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content:
              const Text('¿Estas seguro de que deseas eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(user);
              },
              child: const Text('Si'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateMovieDialog(MovieModel movie) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.movie_creation_outlined),
            title: const Text('Editar Pelicula'),
            content: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 33, right: 33),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 11,
                      width: MediaQuery.of(context).size.width * 0.5,
                    ),
                    _displayFormField(_titleController, 'Titulo'),
                    _displayFormField(_descriptionController, 'Descripcion'),
                    _displayDropdownCategoryFormField(),
                    _displayDropdownSubscriptionPackageFormField(),
                    _displayFormField(_imageUrlController, 'URL de la imagen'),
                    _displayFormField(_trailerUrlController, 'URL del trailer'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => _updateMovie(movie),
                  child: const Text('Guardar')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearFields();
                },
                child: const Text('Cancelar'),
              ),
            ],
          );
        });
  }

  void _showUpdateUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 33, right: 33),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 11,
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                  _displayFormField(_nameController, 'Nombre'),
                  _displayEmailFormField(),
                  _displayPasswordFormField(),
                  _displayDropdownSubscriptionPackageFormField(),
                  _displayDropdownTypeFormField(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _updateUser(user),
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _updateMovie(MovieModel movie) async {
    movie.title = _titleController.text;
    movie.description = _descriptionController.text;
    movie.category = _categoryController.text;
    movie.subscriptionPackage = _subscriptionPackageController.text;
    movie.imageUrl = _imageUrlController.text;
    movie.trailerUrl = _trailerUrlController.text;

    if (await Controller(context).updateMovie(movie)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelicula actualizada con exito'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar la pelicula'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _clearFields();
    setState(() {
      _fetchMovies();
    });
  }

  void _updateUser(UserModel user) async {
    user.name = _nameController.text;
    user.email = _emailController.text;
    user.password = _passwordController.text;
    user.subscriptionPackage = _subscriptionPackageController.text;
    user.type = _typeController.text;

    if (await Controller(context).updateUser(user)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado con exito'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el usuario'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _clearFields();
    setState(() {
      _fetchUsers();
    });
  }

  void _deleteMovie(MovieModel movie) async {
    if (await Controller(context).deleteMovie(movie)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelicula eliminada con exito'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la pelicula'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() {
      _fetchMovies();
    });
  }

  void _deleteUser(UserModel user) async {
    if (await Controller(context).deleteUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado con exito'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el usuario'),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() {
      _fetchUsers();
    });
  }

  void _showCreateMovieDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.movie_creation_outlined),
          title: const Text('Crear Pelicula'),
          content: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 33, right: 33),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 11,
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                  _displayFormField(_titleController, 'Titulo'),
                  _displayFormField(_descriptionController, 'Descripcion'),
                  _displayDropdownCategoryFormField(),
                  _displayDropdownSubscriptionPackageFormField(),
                  _displayPickUpImage(),
                  _displayFormField(_trailerUrlController, 'URL del trailer'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: _createMovie, child: const Text('Guardar')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _displayPickUpImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: _imageUrlController,
        onTap: () async {
          try {
            final ImagePicker picker = ImagePicker();

            final XFile? img =  await picker.pickImage(source: ImageSource.gallery);

            if (img == null) {
              return;
            }

            // convertir la imagen a un blob
            blob = File(img.path);
          } catch (e) {
            log('imgpicker error: ${e.toString()}');
          }

          setState(() {
            _imageUrlController.text = 'SE AGREGO UNA IMAGEN';
          });
        },
        readOnly: true,
        decoration: const InputDecoration(
          hintText: 'Imagenes',
          filled: true,
          prefixIcon: Icon(Icons.access_time_outlined),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(),
        ),
        validator: (value) {
          if (_imageUrlController.text.trim().isEmpty) {
            return 'Ingrese un valor';
          }
          return null;
        },
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          title: const Text('Crear Usuario'),
          content: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 33, right: 33),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 11,
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                  _displayFormField(_nameController, 'Nombre'),
                  _displayEmailFormField(),
                  _displayPasswordFormField(),
                  _displayDropdownSubscriptionPackageFormField(),
                  _displayDropdownTypeFormField(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: _createUser, child: const Text('Guardar')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _displayEmailFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          // Validar que el campo no tenga solo espacios en blanco
          if (value!.trim().isEmpty) {
            return 'Este campo no puede tener solo espacios en blanco';
          }
          // Validar que el campo no esté vacío
          if (value!.isEmpty) {
            return 'Este campo es requerido';
          }
          // Expresion regular para validar un email
          String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
          RegExp regExp = RegExp(emailPattern);
          if (!regExp.hasMatch(value)) {
            return 'Email invalido';
          }
          return null;
        },
      ),
    );
  }

  Widget _displayPasswordFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          // Validar que el campo no tenga solo espacios en blanco
          if (value!.trim().isEmpty) {
            return 'Este campo no puede tener solo espacios en blanco';
          }
          // Validar que el campo no esté vacío
          if (value!.isEmpty) {
            return 'Este campo es requerido';
          }
          // Validar que el texto tenga al menos 6 caracteres
          if (value.length < 6) {
            return 'La contraseña debe tener al menos 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _displayFormField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          // Validar que el campo no tenga solo espacios en blanco
          if (value!.trim().isEmpty) {
            return 'Este campo no puede tener solo espacios en blanco';
          }
          // Validar que el campo no esté vacío
          if (value!.isEmpty) {
            return 'Este campo es requerido';
          }
          return null;
        },
      ),
    );
  }

  Widget _displayDropdownCategoryFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: DropdownButtonFormField(
        value: _categoryController.text,
        items: categoryitems,
        onChanged: (value) {
          setState(() {
            _categoryController.text = value.toString();
          });
        },
        decoration: const InputDecoration(
          labelText: 'Categoria',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _displayDropdownSubscriptionPackageFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: DropdownButtonFormField(
        value: _subscriptionPackageController.text,
        items: subscriptionPackageitems,
        onChanged: (value) {
          setState(() {
            _subscriptionPackageController.text = value.toString();
          });
        },
        decoration: const InputDecoration(
          labelText: 'Paquete de suscripcion',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _displayDropdownTypeFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: DropdownButtonFormField(
        value: _typeController.text,
        items: typeitems,
        onChanged: (value) {
          setState(() {
            _typeController.text = value.toString();
          });
        },
        decoration: const InputDecoration(
          labelText: 'Tipo de usuario',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _createMovie() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    MovieModel movie = MovieModel(
      id: '',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _categoryController.text,
      subscriptionPackage: _subscriptionPackageController.text,
      imageUrl: _imageUrlController.text,
      trailerUrl: _trailerUrlController.text,
      createdAt: '',
    );

    await Controller(context).createMovie(movie, blob).then((value) {
      if (value) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelicula creada con exito'),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la pelicula'),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _clearFields();
    setState(() {
      _fetchMovies();
    });
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    UserModel user = UserModel(
      id: '',
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      subscriptionPackage: _subscriptionPackageController.text,
      type: _typeController.text,
      createdAt: '',
    );

    await Controller(context).createUser(user).then((value) {
      if (value) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado con exito'),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el usuario'),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _clearFields();
    setState(() {
      _fetchUsers();
    });
  }

  void _clearFields() {
    _titleController.clear();
    _descriptionController.clear();
    _categoryController.text = 'Accion';
    _subscriptionPackageController.text = 'BASICO';
    _imageUrlController.clear();
    _trailerUrlController.clear();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _typeController.text = 'USER';
  }
}
