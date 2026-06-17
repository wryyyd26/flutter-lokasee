import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/venue_model.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';

class BookingScreen extends StatefulWidget {
  final Venue venue;

  const BookingScreen({
    super.key,
    required this.venue,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final VenueService _venueService = VenueService();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  int _selectedDuration = 1;
  bool _isLoading = false;

  String _selectedPaymentMethod = 'offline';
  XFile? _paymentProofFile;
  Uint8List? _paymentProofBytes;

  final TextEditingController _noteController = TextEditingController();

  final List<String> _availableTimes = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  final List<int> _durations = [1, 2, 3, 4];

  final String _bankName = 'BCA';
  final String _bankAccountNumber = '1234567890';
  final String _bankAccountName = 'Lokasee Venue';

  bool get _isDailyRental {
    final category = widget.venue.category.toLowerCase();
    final name = widget.venue.name.toLowerCase();

    return category.contains('event') ||
        category.contains('gedung') ||
        category.contains('aula') ||
        category.contains('hall') ||
        name.contains('gedung') ||
        name.contains('aula') ||
        name.contains('hall');
  }

  bool get _isHourlyRental {
    return !_isDailyRental;
  }

  bool get _isTransferPayment {
    return _selectedPaymentMethod == 'transfer';
  }

  int get _basePrice {
    final onlyNumbers = widget.venue.price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyNumbers) ?? 0;
  }

  int get _totalPrice {
    if (_isDailyRental) return _basePrice;
    return _basePrice * _selectedDuration;
  }

  String get _selectedDurationText {
    return _isDailyRental ? '1 hari / Full Day' : '$_selectedDuration jam';
  }

  String get _selectedBookingTime {
    return _isDailyRental ? 'Full Day' : _selectedTime;
  }

  String get _selectedPaymentMethodText {
    return _isTransferPayment ? 'Transfer Bank' : 'Bayar Offline di Loket';
  }

  String _formatRupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  String _dayName(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  String _fullDayName(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];

    return days[date.weekday % 7];
  }

  String _monthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[date.month - 1];
  }

  String _formatFullDate(DateTime date) {
    return '${_fullDayName(date)}, ${date.day} ${_monthName(date)} ${date.year}';
  }

  String _endTime(String startTime, int duration) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    final endHour = hour + duration;
    return '${endHour.toString().padLeft(2, '0')}:$minute';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickPaymentProof() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _paymentProofFile = pickedFile;
        _paymentProofBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadPaymentProofIfNeeded() async {
    if (!_isTransferPayment) {
      return '';
    }

    final proofFile = _paymentProofFile;
    final proofBytes = _paymentProofBytes;

    if (proofFile == null || proofBytes == null) {
      throw Exception('Bukti transfer wajib diupload.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${widget.venue.id}_$timestamp.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('payment_proofs')
        .child(fileName);

    final uploadTask = await ref.putData(
      proofBytes,
      SettableMetadata(
        contentType: proofFile.mimeType ?? 'image/jpeg',
      ),
    );

    return uploadTask.ref.getDownloadURL();
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      if (_isTransferPayment && _paymentProofFile == null) {
        throw Exception('Silakan upload bukti transfer terlebih dahulu.');
      }

      final bookingTime = _selectedBookingTime;
      final duration = _isDailyRental ? 1 : _selectedDuration;
      final durationText = _selectedDurationText;
      final note = _noteController.text.trim();

      final paymentProofUrl = await _uploadPaymentProofIfNeeded();

      await _venueService.createBooking(
        venue: widget.venue,
        bookingDate: _selectedDate,
        bookingDateText: _formatFullDate(_selectedDate),
        bookingTime: bookingTime,
        duration: duration,
        durationText: durationText,
        totalPrice: _totalPrice,
        note: note,
        paymentMethod: _selectedPaymentMethod,
        paymentProofUrl: paymentProofUrl,
        bankName: _bankName,
        bankAccountNumber: _bankAccountNumber,
        bankAccountName: _bankAccountName,
      );

      if (!mounted) return;

      final successMessage = _isTransferPayment
          ? 'Booking berhasil dikirim. Menunggu verifikasi pembayaran owner.'
          : 'Booking berhasil dikirim. Pembayaran dilakukan offline di loket.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildModernDatePicker() {
    final today = DateTime.now();

    final dates = List.generate(14, (index) {
      return DateTime(
        today.year,
        today.month,
        today.day + index,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDate(date, _selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 78,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.white,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.055),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        index == 0 ? 'Hari ini' : _dayName(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white.withValues(alpha: 0.88)
                              : AppColors.neutral,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color:
                              isSelected ? AppColors.accent : AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _monthName(date),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white.withValues(alpha: 0.88)
                              : AppColors.neutral,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatFullDate(_selectedDate),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyDatePicker() {
    final today = DateTime.now();

    final dates = List.generate(7, (index) {
      return DateTime(
        today.year,
        today.month,
        today.day + index,
      );
    });

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDate(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayName(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _monthName(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.neutral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.10)
              : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: AppColors.accent,
              onChanged: (selectedValue) {
                if (selectedValue == null) return;
                setState(() {
                  _selectedPaymentMethod = selectedValue;
                });
              },
            ),
            const SizedBox(width: 4),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.neutral,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTransferPaymentBox() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nomor Rekening',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_bankName - $_bankAccountNumber',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'a.n. $_bankAccountName',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Setelah transfer, upload bukti pembayaran sebelum konfirmasi booking.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.76),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isLoading ? null : _pickPaymentProof,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _paymentProofFile == null
                    ? AppColors.accent.withValues(alpha: 0.25)
                    : AppColors.accent,
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _paymentProofFile == null
                      ? Icons.upload_file_rounded
                      : Icons.check_circle_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _paymentProofFile == null
                        ? 'Upload Bukti Transfer'
                        : 'Bukti transfer dipilih',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral,
                ),
              ],
            ),
          ),
        ),
        if (_paymentProofBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              _paymentProofBytes!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOfflinePaymentBox() {
    return _InfoCard(
      icon: Icons.storefront_rounded,
      text:
          'Pembayaran dilakukan langsung di loket venue. Booking akan masuk ke owner dan menunggu konfirmasi.',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalText =
        _totalPrice > 0 ? _formatRupiah(_totalPrice) : widget.venue.price;

    final timeText = _isDailyRental
        ? 'Full Day'
        : '$_selectedTime - ${_endTime(_selectedTime, _selectedDuration)}';

    final durationText = _selectedDurationText;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Booking Venue',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '4.8 Excellent',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _isDailyRental ? 'Full Day' : 'Per Jam',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.venue.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.venue.location,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.venue.price,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            const _SectionTitle(title: 'Pilih Tanggal'),
            const SizedBox(height: 12),
            if (_isHourlyRental)
              _buildModernDatePicker()
            else
              _buildDailyDatePicker(),

            const SizedBox(height: 26),
            if (_isDailyRental) ...[
              const _SectionTitle(title: 'Waktu Sewa'),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.event_available_rounded,
                text:
                    'Venue ini disewa untuk 1 hari penuh. Pemilihan jam tidak diperlukan.',
              ),
            ] else ...[
              const _SectionTitle(title: 'Pilih Jam'),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableTimes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final time = _availableTimes[index];
                    final isSelected = _selectedTime == time;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTime = time);
                      },
                      child: Container(
                        width: 112,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.accent : AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Text(
                          '$time\n- ${_endTime(time, _selectedDuration)}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 26),
            const _SectionTitle(title: 'Durasi Sewa'),
            const SizedBox(height: 12),
            if (_isDailyRental)
              Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent,
                    width: 1.3,
                  ),
                ),
                child: const Text(
                  '1 hari / Full Day',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              Row(
                children: _durations.map((duration) {
                  final isSelected = _selectedDuration == duration;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: duration == _durations.last ? 0 : 10,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedDuration = duration);
                        },
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$duration jam',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 26),
            const _SectionTitle(title: 'Metode Pembayaran'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              value: 'offline',
              title: 'Bayar Offline di Loket',
              subtitle: 'Bayar langsung saat datang ke venue.',
              icon: Icons.storefront_rounded,
            ),
            _buildPaymentOption(
              value: 'transfer',
              title: 'Transfer Bank',
              subtitle: 'Transfer sekarang dan upload bukti pembayaran.',
              icon: Icons.account_balance_rounded,
            ),
            if (_isTransferPayment)
              _buildTransferPaymentBox()
            else
              _buildOfflinePaymentBox(),

            const SizedBox(height: 26),
            const _SectionTitle(title: 'Catatan'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: AppColors.neutral,
                  ),
                  hintText: 'Tulis catatan atau permintaan khusus',
                  hintStyle: TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),
            const _SectionTitle(title: 'Ringkasan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Venue', value: widget.venue.name),
                  _SummaryRow(
                    label: 'Tanggal',
                    value: _formatFullDate(_selectedDate),
                  ),
                  _SummaryRow(label: 'Waktu', value: timeText),
                  _SummaryRow(label: 'Durasi', value: durationText),
                  _SummaryRow(
                    label: 'Pembayaran',
                    value: _selectedPaymentMethodText,
                  ),
                  if (_isTransferPayment)
                    _SummaryRow(
                      label: 'Rekening',
                      value: '$_bankName $_bankAccountNumber',
                    ),
                  const Divider(height: 26),
                  _SummaryRow(
                    label: 'Total',
                    value: totalText,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.white,
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Konfirmasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isTotal ? AppColors.accent : AppColors.primary,
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}