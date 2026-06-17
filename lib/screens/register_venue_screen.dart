import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String selectedCategory = venueCategories.first;
  bool _isLoading = false;

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu harus login terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawPrice = _priceController.text.trim();
      final formattedPrice =
          rawPrice.toLowerCase().contains('rp') ? rawPrice : 'Rp $rawPrice';

      await FirebaseFirestore.instance.collection('venues').add({
        'name': _nameController.text.trim(),
        'category': selectedCategory,
        'location': _locationController.text.trim(),
        'price': formattedPrice,
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'rating': 0.0,
        'ownerId': user.uid,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue berhasil disimpan ke Firestore.'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan venue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) return false;

    return uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Venue'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
                    Icon(
                      Icons.add_business_rounded,
                      color: AppColors.accent,
                      size: 38,
                    ),
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
                      'Isi informasi venue dan masukkan link URL gambar agar venue bisa tampil dengan foto.',
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
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.neutral.withValues(alpha: 0.12),
                  ),
                ),
                child: imageUrl.isEmpty || !_isValidImageUrl(imageUrl)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: AppColors.accent,
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Preview gambar venue',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Masukkan URL gambar di bawah',
                            style: TextStyle(
                              color: AppColors.neutral,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.neutral,
                                  size: 38,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gambar gagal dimuat',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: 100,
              child: TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar Venue',
                  hintText: 'Contoh: https://example.com/gambar.jpg',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                onChanged: (_) {
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URL gambar wajib diisi';
                  }

                  if (!_isValidImageUrl(value)) {
                    return 'Masukkan URL gambar yang valid';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: 130,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Venue',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama venue wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: 170,
              child: DropdownButtonFormField<String>(
                value: selectedCategory,
                items: venueCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
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
            FadeSlideIn(
              delay: 210,
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Venue',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lokasi venue wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: 250,
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Harga Venue',
                  hintText: 'Contoh: 100.000 atau Rp 100.000/jam',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga venue wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: 290,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Venue',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi venue wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: 330,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveVenue,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt_rounded),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'Simpan Venue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
