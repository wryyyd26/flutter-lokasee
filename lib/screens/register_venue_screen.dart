import 'package:flutter/material.dart';

import '../data/venue_data.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slide_in.dart';

class RegisterVenueScreen extends StatefulWidget {
  const RegisterVenueScreen({super.key});

  @override
  State<RegisterVenueScreen> createState() => _RegisterVenueScreenState();
}

class _RegisterVenueScreenState extends State<RegisterVenueScreen> {
  String selectedCategory = venueCategories.first;

  void _showSaveDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Data Venue'),
        content: const Text(
          'Data venue belum tersimpan ke Firebase..',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Venue')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_business_rounded,
                      color: AppColors.accent, size: 38),
                  SizedBox(height: 16),
                  Text(
                    'Buat venue kamu\nlebih mudah ditemukan',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Isi informasi utama venue. Penyimpanan data baru akan dihubungkan pada progress berikutnya.',
                    style: TextStyle(
                      color: AppColors.background,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: 80,
            child: Container(
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: AppColors.neutral.withValues(alpha: 0.12)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.accent, size: 34),
                  SizedBox(height: 8),
                  Text(
                    'Upload gambar venue',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Placeholder UI',
                    style: TextStyle(color: AppColors.neutral, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const FadeSlideIn(
            delay: 130,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Nama Venue',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: 170,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: venueCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedCategory = value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Kategori Venue',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const FadeSlideIn(
            delay: 210,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Lokasi Venue',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const FadeSlideIn(
            delay: 250,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Harga Venue',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const FadeSlideIn(
            delay: 290,
            child: TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi Venue',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: 330,
            child: ElevatedButton.icon(
              onPressed: () => _showSaveDialog(context),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Simpan Venue'),
            ),
          ),
        ],
      ),
    );
  }
}
