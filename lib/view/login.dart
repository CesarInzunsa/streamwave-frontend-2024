import 'dart:developer';

import 'package:flutter/material.dart';

import '../controller/controller.dart';
import '../model/user_model.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Llave para el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamWave'),
      ),
      body: _displayLoginPage(),
    );
  }

  Widget _displayLoginPage() {
    return Padding(
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
            _displayEmailFormField(),
            _displayPasswordFormField(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _displayLoginButton(),
                _displayCancelButton(),
              ],
            ),
          ],
        ),
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

  Widget _displayLoginButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          String email = _emailController.text;
          String password = _passwordController.text;

          UserModel user = await Controller(context).login(email, password);

          log('id: ${user.id}');
          log('email: ${user.email}');
          log('type: ${user.type}');
          log('suscripcion: ${user.subscriptionPackage}');

          if (user.id != '') {
            if (user.type == 'ADMIN') {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/control_panel',
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(user: user),
                ),
                (route) {
                  return false;
                },
              );
            }
          } else {
            _showErrorMessage();
          }
        }
      },
      child: const Text('Iniciar sesión'),
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
}
