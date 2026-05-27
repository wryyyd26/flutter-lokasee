import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'home_screen.dart';

class RegisterScreen extends StatelessWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun\nBaru',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Daftar untuk mulai mencari venue atau mendaftarkan tempat milikmu.',
                style: TextStyle(
                  color: AppColors.neutral,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 34),
              const TextField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
