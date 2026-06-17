import 'package:flutter/material.dart';

import '../models/venue_model.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pressable_card.dart';
import '../widgets/smooth_page_route.dart';
import '../widgets/venue_image.dart';
import 'venue_detail_screen.dart';

class VenueListScreen extends StatefulWidget {
  final String category;
  final List<Venue> venues;

  const VenueListScreen({
    super.key,
    required this.category,
    required this.venues,
  });

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VenueService _venueService = VenueService();

  String _searchQuery = '';
  String _selectedFilter = 'Best match';

  final List<String> _filters = const [
    'Best match',
    'Termurah',
    'Rating tinggi',
  ];

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

  String _categorySubtitle(String category) {
    switch (category) {
      case 'Sport Town':
        return 'Lapangan olahraga dan arena aktivitas';
      case 'Dining Room':
        return 'Ruang makan, restoran, dan private dining';
      case 'Event Room':
        return 'Aula, ballroom, meeting room, dan ruang acara';
      default:
        return 'Pilihan venue terbaik';
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

  int _extractPriceNumber(String priceText) {
    final onlyNumber = priceText.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyNumber.isEmpty) return 0;
    return int.tryParse(onlyNumber) ?? 0;
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

  List<Venue> _applyFilter(List<Venue> venues) {
    final result = venues.where(_matchesSearch).toList();

    if (_selectedFilter == 'Termurah') {
      result.sort((a, b) {
        return _extractPriceNumber(a.price).compareTo(
          _extractPriceNumber(b.price),
        );
      });
    } else if (_selectedFilter == 'Rating tinggi') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return result;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
          hintText: 'Cari venue di ${widget.category}...',
          hintStyle: const TextStyle(color: AppColors.neutral),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.neutral,
          ),
          suffixIcon: _searchQuery.trim().isEmpty
              ? null
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = label);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.neutral.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, Venue venue, int index) {
    return FadeSlideIn(
      delay: 160 + (index * 65),
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
                    width: 96,
                    height: 106,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 106,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
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
                                venue.category,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
                        const SizedBox(height: 5),
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
                        const Spacer(),
                        Text(
                          venue.price,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.location_off_rounded,
            color: AppColors.neutral,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Tidak ada hasil untuk "$_searchQuery"'
                : 'Belum ada venue untuk kategori ini',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Coba kata kunci lain seperti nama venue, lokasi, atau harga.'
                : 'Venue yang didaftarkan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 12,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Hapus pencarian'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeSlideIn(
      delay: 70,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _categoryIcon(widget.category),
                color: AppColors.accent,
                size: 31,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categorySubtitle(widget.category),
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Venue> venues) {
    final filteredVenues = _applyFilter(venues);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: 100,
          child: _buildSearchBox(),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: 125,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(filter),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: 140,
          child: Row(
            children: [
              const Text(
                'Daftar venue',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredVenues.length} tersedia',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filteredVenues.isEmpty)
          _buildEmptyState()
        else
          ...filteredVenues.asMap().entries.map((entry) {
            return _buildVenueCard(
              context,
              entry.value,
              entry.key,
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalVenues = widget.venues.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Venue',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (hasLocalVenues)
              _buildBody(widget.venues)
            else
              StreamBuilder<List<Venue>>(
                stream: _venueService.getVenuesByCategory(widget.category),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 60),
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    );
                  }

                  final venues = snapshot.data ?? [];

                  return _buildBody(venues);
                },
              ),
          ],
        ),
      ),
    );
  }
}
