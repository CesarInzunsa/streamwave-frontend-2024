// flutter
import 'package:flutter/material.dart';

// business logic
import '../controller/controller.dart';
import '../model/user_model.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // llave del formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _subscriptionPackageController = TextEditingController(text: 'BASICO');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamWave'),
      ),
      body: _displayRegisterPage(),
    );
  }

  Widget _displayRegisterPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 11,
        bottom: 11,
        left: MediaQuery.of(context).size.width * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _displayNameFormField(),
            _displayEmailFormField(),
            _displayPasswordFormField(),
            _displayConfirmPasswordFormField(),
            _displayDropdownSubscriptionPackageFormField(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _displayRegisterButton(),
                _displayCancelButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayNameFormField(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Nombre',
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
          return null;
        },
      ),
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

  Widget _displayConfirmPasswordFormField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: _confirmPasswordController,
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
          // Validar que el texto sea el mismo que el campo de contraseña
          if (value != _passwordController.text) {
            return 'Las contraseñas no coinciden';
          }
          return null;
        },
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

  Widget _displayRegisterButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          UserModel user = UserModel(
            id: '',
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            subscriptionPackage: _subscriptionPackageController.text,
            type: 'USER',
            createdAt: '',
          );
          if (await Controller(context).createUser(user)) {
            Navigator.pushReplacementNamed(context, '/welcome');
            _showSuccessMessage();
          } else {
            _showErrorMessage();
          }
        }
      },
      child: const Text('Crear cuenta'),
    );
  }

  Widget _displayCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text('Cancelar'),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Email o contraseña incorrectos'),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Registro exitoso, inicie sesión para continuar'),
      ),
    );
  }
}
