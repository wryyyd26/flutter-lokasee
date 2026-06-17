import 'package:flutter/material.dart';

import '../models/venue_model.dart';
import '../screens/booking_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/smooth_page_route.dart';
import '../widgets/venue_image.dart';

class VenueDetailScreen extends StatelessWidget {
  final Venue venue;

  const VenueDetailScreen({
    super.key,
    required this.venue,
  });

  Widget _buildVenueImage() {
    return VenueImage(
      imageUrl: venue.imageUrl,
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: FadeSlideIn(
            delay: 350,
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      page: BookingScreen(venue: venue),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Pesan Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Detail Venue',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: 80,
              child: Stack(
                children: [
                  Hero(
                    tag: venue.name,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _buildVenueImage(),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${venue.rating} Excellent',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: 140,
              child: Text(
                venue.name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: 180,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    text: venue.category,
                  ),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    text: venue.location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: 220,
              child: Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.payments_outlined,
                      label: 'Harga',
                      value: venue.price,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _InfoCard(
                      icon: Icons.access_time_rounded,
                      label: 'Jam buka',
                      value: '08.00 - 22.00',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const FadeSlideIn(
              delay: 260,
              child: Text(
                'Deskripsi',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: 300,
              child: Text(
                venue.description,
                style: const TextStyle(
                  color: AppColors.neutral,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.neutral,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
