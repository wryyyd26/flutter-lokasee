import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/venue_model.dart';
import '../services/location_service.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pressable_card.dart';
import '../widgets/smooth_page_route.dart';
import '../widgets/venue_image.dart';
import 'login_screen.dart';
import 'my_booking_screen.dart';
import 'owner_booking_screen.dart';
import 'register_venue_screen.dart';
import 'venue_detail_screen.dart';
import 'venue_list_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  static const List<String> venueCategories = [
    'Sport Town',
    'Dining Room',
    'Event Room',
  ];

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VenueService _venueService = VenueService();
  final LocationService _locationService = LocationService();

  String _searchQuery = '';

  Position? _currentPosition;
  bool _isLocationLoading = false;
  String? _locationError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Sport Town':
        return Icons.sports_soccer_rounded;
      case 'Dining Room':
        return Icons.restaurant_rounded;
      case 'Event Room':
        return Icons.meeting_room_rounded;
      default:
        return Icons.location_city_rounded;
    }
  }

  String _categoryDescription(String category) {
    switch (category) {
      case 'Sport Town':
        return 'Futsal, badminton, mini soccer';
      case 'Dining Room':
        return 'Private dining dan ruang makan';
      case 'Event Room':
        return 'Aula, meeting, dan ruang acara';
      default:
        return 'Venue pilihan';
    }
  }

  String _categoryKeywords(String category) {
    switch (category) {
      case 'Sport Town':
        return 'sport olahraga futsal badminton mini soccer lapangan gor basket';
      case 'Dining Room':
        return 'dining room restaurant restoran makan private dining cafe food';
      case 'Event Room':
        return 'event room aula meeting seminar acara gedung rapat ballroom';
      default:
        return '';
    }
  }

  bool _matchesSearch(Venue venue) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final searchableText = [
      venue.name,
      venue.category,
      venue.location,
      venue.price,
      venue.description,
      venue.rating.toString(),
      _categoryKeywords(venue.category),
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi berhasil digunakan. Venue akan diurutkan dari yang terdekat.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLocationLoading = false;
        _locationError = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double? _distanceToVenue(Venue venue) {
    final position = _currentPosition;

    if (position == null) return null;
    if (venue.latitude == null || venue.longitude == null) return null;

    return _locationService.distanceInKm(
      userLatitude: position.latitude,
      userLongitude: position.longitude,
      venueLatitude: venue.latitude!,
      venueLongitude: venue.longitude!,
    );
  }

  List<Venue> _sortByNearest(List<Venue> venues) {
    if (_currentPosition == null) return venues;

    final sortedVenues = [...venues];

    sortedVenues.sort((a, b) {
      final distanceA = _distanceToVenue(a);
      final distanceB = _distanceToVenue(b);

      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    return sortedVenues;
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

  Widget _buildRenterNotificationButton() {
    return StreamBuilder<int>(
      stream: _venueService.getUnreadRenterNotificationCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Status Booking Saya',
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    page: const MyBookingScreen(),
                  ),
                );
              },
              icon: Icon(
                hasUnread
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Cari futsal, private dining, event room...',
          hintStyle: const TextStyle(color: AppColors.neutral),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.neutral,
          ),
          suffixIcon: _searchQuery.trim().isEmpty
              ? const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accent,
                )
              : IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.neutral,
                  ),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 1.4,
            ),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLocationLoading ? null : _useCurrentLocation,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.accent,
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isLocationLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded),
        label: Text(
          _currentPosition == null
              ? 'Gunakan lokasi saya'
              : 'Venue diurutkan dari terdekat',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.neutral,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada venue untuk "$_searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba cari nama venue, lokasi, kategori, atau jenis tempatnya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _clearSearch,
            child: const Text('Hapus pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, Venue venue, int index) {
    final distanceKm = _distanceToVenue(venue);
    final distanceText =
        distanceKm == null ? null : _locationService.formatDistance(distanceKm);

    return FadeSlideIn(
      delay: 280 + (index * 70),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PressableCard(
          onTap: () {
            Navigator.push(
              context,
              SmoothPageRoute(
                page: VenueDetailScreen(venue: venue),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: VenueImage(
                    imageUrl: venue.imageUrl,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentPosition != null
                              ? 'Nearby'
                              : _searchQuery.trim().isEmpty
                                  ? 'Recommended'
                                  : venue.category,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        venue.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.neutral,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.neutral,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            venue.price,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            FadeSlideIn(
              delay: 40,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasee',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Find your perfect venue',
                          style: TextStyle(
                            color: AppColors.neutral,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icon notifikasi penyewa:
                  // Penyewa klik ini untuk melihat status bookingnya.
                  _buildRenterNotificationButton(),

                  // Icon pesanan masuk owner:
                  // Owner klik ini untuk melihat pesanan masuk.
                  IconButton(
                    tooltip: 'Pesanan Masuk',
                    onPressed: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          page: const OwnerBookingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.inbox_rounded,
                      color: AppColors.primary,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Logout',
                    onPressed: () => _logout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: 90,
              child: _buildSearchBox(),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: 105,
              child: _buildLocationButton(),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _locationError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!isSearching) ...[
              FadeSlideIn(
                delay: 130,
                child: Container(
                  height: 185,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -28,
                        top: -30,
                        child: Container(
                          width: 126,
                          height: 126,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking venue\nlebih cepat & rapi',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 26,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    page: const RegisterVenueScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_business_rounded),
                              label: const Text('Daftarkan Venue'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const FadeSlideIn(
                delay: 170,
                child: _SectionHeader(
                  title: 'Kategori populer',
                  action: 'Lihat semua',
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: 210,
                child: SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: HomeScreen.venueCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final category = HomeScreen.venueCategories[index];
                      return _CategoryPill(
                        title: category,
                        subtitle: _categoryDescription(category),
                        icon: _categoryIcon(category),
                        onTap: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              page: VenueListScreen(
                                category: category,
                                venues: const [],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
            StreamBuilder<List<Venue>>(
              stream: _venueService.getVenues(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Belum ada venue tersedia',
                        style: TextStyle(color: AppColors.neutral),
                      ),
                    ),
                  );
                }

                final venues = snapshot.data!;

                final searchedVenues = isSearching
                    ? venues.where(_matchesSearch).toList()
                    : venues.toList();

                final sortedVenues = _sortByNearest(searchedVenues);

                final displayedVenues = isSearching || _currentPosition != null
                    ? sortedVenues
                    : sortedVenues.take(3).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      delay: isSearching ? 120 : 250,
                      child: _SectionHeader(
                        title: isSearching
                            ? 'Hasil pencarian'
                            : _currentPosition != null
                                ? 'Venue terdekat'
                                : 'Rekomendasi venue',
                        action: isSearching
                            ? '${displayedVenues.length} hasil'
                            : _currentPosition != null
                                ? 'Nearby'
                                : 'Promo',
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (displayedVenues.isEmpty)
                      _buildEmptySearchResult()
                    else
                      ...displayedVenues.asMap().entries.map((entry) {
                        return _buildVenueCard(
                          context,
                          entry.value,
                          entry.key,
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;

  const _SectionHeader({
    required this.title,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        width: 184,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
                size: 25,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.neutral,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
