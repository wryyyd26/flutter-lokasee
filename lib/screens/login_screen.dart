import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Masuk ke\nLokasee',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Temukan venue yang cocok untuk olahraga, makan bersama, atau acara komunitas.',
                style: TextStyle(
                  color: AppColors.neutral,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 34),
              const TextField(
                keyboardType: TextInputType.emailAddress,
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
                child: const Text('Login'),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun?',
                    style: TextStyle(color: AppColors.neutral),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RegisterScreen.routeName);
                    },
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
