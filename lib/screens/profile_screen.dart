import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'my_booking_screen.dart';
import 'owner_booking_screen.dart';
import 'register_venue_screen.dart';
import '../widgets/smooth_page_route.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  User? get user => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> _getUserData() async {
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return doc.data();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          final name = data?['name'] ?? 'User';
          final email = data?['email'] ?? (user?.email ?? '');
          final photoUrl = data?['photoUrl'];

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // ================= PROFILE CARD =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: photoUrl != null && photoUrl != ''
                            ? NetworkImage(photoUrl)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: photoUrl == null || photoUrl == ''
                            ? const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= MENU =================
                _MenuCard(
                  icon: Icons.event_available_rounded,
                  title: 'Booking Saya',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: const MyBookingScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.add_business_rounded,
                  title: 'Daftarkan Venue',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: const RegisterVenueScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.inbox_rounded,
                  title: 'Pesanan Masuk (Owner)',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: const OwnerBookingScreen(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // ================= LOGOUT =================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.neutral),
          ],
        ),
      ),
    );
  }
}
