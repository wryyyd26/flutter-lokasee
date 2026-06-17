import 'package:flutter/material.dart';

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

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  int _selectedDuration = 1;
  bool _isLoading = false;

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

  int get _basePrice {
    final onlyNumbers = widget.venue.price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyNumbers) ?? 0;
  }

  int get _totalPrice {
    if (_isDailyRental) return _basePrice;
    return _basePrice * _selectedDuration;
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

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final bookingTime = _isDailyRental ? 'Full Day' : _selectedTime;
      final duration = _isDailyRental ? 1 : _selectedDuration;
      final note = _noteController.text.trim();

      await _venueService.createBooking(
        venue: widget.venue,
        bookingDate: _selectedDate,
        bookingDateText: _formatFullDate(_selectedDate),
        bookingTime: bookingTime,
        duration: duration,
        totalPrice: _totalPrice,
        note: note,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking berhasil dikirim. Menunggu persetujuan owner.',
          ),
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

    final durationText =
        _isDailyRental ? '1 hari / Full Day' : '$_selectedDuration jam';

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
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

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
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
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
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.primary,
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
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.primary,
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
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.neutral,
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
            ),
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
