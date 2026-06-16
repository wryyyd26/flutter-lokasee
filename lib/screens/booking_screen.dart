import 'package:flutter/material.dart';

import '../models/venue_model.dart';
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
    if (_isDailyRental) {
      return _basePrice;
    }

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

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Booking UI berhasil. Firebase disambungkan setelah ini.',
        ),
        backgroundColor: AppColors.primary,
      ),
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
            _VenueHeaderCard(
              venue: widget.venue,
              isDailyRental: _isDailyRental,
            ),
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Pilih Tanggal'),
            const SizedBox(height: 12),
            _DatePickerRow(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
              dayName: _dayName,
              monthName: _monthName,
            ),
            const SizedBox(height: 26),
            if (_isDailyRental) ...[
              const _SectionTitle(title: 'Waktu Sewa'),
              const SizedBox(height: 12),
              const _InfoCard(
                icon: Icons.event_available_rounded,
                text:
                    'Venue ini disewa untuk 1 hari penuh. Pemilihan jam tidak diperlukan.',
              ),
            ] else ...[
              const _SectionTitle(title: 'Pilih Jam'),
              const SizedBox(height: 12),
              _TimePickerRow(
                availableTimes: _availableTimes,
                selectedTime: _selectedTime,
                selectedDuration: _selectedDuration,
                endTimeBuilder: _endTime,
                onTimeSelected: (time) {
                  setState(() => _selectedTime = time);
                },
              ),
            ],
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Durasi Sewa'),
            const SizedBox(height: 12),
            if (_isDailyRental)
              const _FullDayDurationCard()
            else
              _DurationPickerRow(
                durations: _durations,
                selectedDuration: _selectedDuration,
                onDurationSelected: (duration) {
                  setState(() => _selectedDuration = duration);
                },
              ),
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Catatan'),
            const SizedBox(height: 12),
            _NoteField(controller: _noteController),
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Ringkasan'),
            const SizedBox(height: 12),
            _SummaryCard(
              venueName: widget.venue.name,
              dateText: _formatFullDate(_selectedDate),
              timeText: timeText,
              durationText: durationText,
              totalText: totalText,
            ),
            const SizedBox(height: 24),
            _BottomConfirmCard(
              totalText: totalText,
              isLoading: _isLoading,
              onPressed: _confirmBooking,
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueHeaderCard extends StatelessWidget {
  final Venue venue;
  final bool isDailyRental;

  const _VenueHeaderCard({
    required this.venue,
    required this.isDailyRental,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          Container(
            width: 86,
            height: 108,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.location_city_rounded,
              color: AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.primary,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${venue.rating} Excellent',
                            style: const TextStyle(
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
                        isDailyRental ? 'Full Day' : 'Per Jam',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        venue.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  venue.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String Function(DateTime) dayName;
  final String Function(DateTime) monthName;

  const _DatePickerRow({
    required this.selectedDate,
    required this.onDateSelected,
    required this.dayName,
    required this.monthName,
  });

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _isSameDate(date, selectedDate);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                children: [
                  Text(
                    dayName(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.neutral,
                      fontSize: 12,
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
}

class _TimePickerRow extends StatelessWidget {
  final List<String> availableTimes;
  final String selectedTime;
  final int selectedDuration;
  final String Function(String startTime, int duration) endTimeBuilder;
  final ValueChanged<String> onTimeSelected;

  const _TimePickerRow({
    required this.availableTimes,
    required this.selectedTime,
    required this.selectedDuration,
    required this.endTimeBuilder,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: availableTimes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final time = availableTimes[index];
          final isSelected = selectedTime == time;

          return GestureDetector(
            onTap: () => onTimeSelected(time),
            child: Container(
              width: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.white,
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
                '$time\n- ${endTimeBuilder(time, selectedDuration)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.primary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DurationPickerRow extends StatelessWidget {
  final List<int> durations;
  final int selectedDuration;
  final ValueChanged<int> onDurationSelected;

  const _DurationPickerRow({
    required this.durations,
    required this.selectedDuration,
    required this.onDurationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: durations.map((duration) {
        final isSelected = selectedDuration == duration;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: duration == durations.last ? 0 : 10,
            ),
            child: GestureDetector(
              onTap: () => onDurationSelected(duration),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Colors.transparent,
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
                child: Text(
                  '$duration jam',
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FullDayDurationCard extends StatelessWidget {
  const _FullDayDurationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;

  const _NoteField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String venueName;
  final String dateText;
  final String timeText;
  final String durationText;
  final String totalText;

  const _SummaryCard({
    required this.venueName,
    required this.dateText,
    required this.timeText,
    required this.durationText,
    required this.totalText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Venue', value: venueName),
          _SummaryRow(label: 'Tanggal', value: dateText),
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
    );
  }
}

class _BottomConfirmCard extends StatelessWidget {
  final String totalText;
  final bool isLoading;
  final VoidCallback onPressed;

  const _BottomConfirmCard({
    required this.totalText,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Konfirmasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
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
