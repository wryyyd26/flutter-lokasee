import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';

class OwnerBookingScreen extends StatefulWidget {
  const OwnerBookingScreen({super.key});

  @override
  State<OwnerBookingScreen> createState() => _OwnerBookingScreenState();
}

class _OwnerBookingScreenState extends State<OwnerBookingScreen> {
  final VenueService _venueService = VenueService();

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _updateStatus(BookingModel booking, String status) async {
    try {
      await _venueService.updateBookingStatus(
        bookingId: booking.id,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Booking berhasil disetujui.'
                : 'Booking berhasil ditolak.',
          ),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isPending = booking.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.meeting_room_rounded,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.venueName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusText(booking.status),
                  style: TextStyle(
                    color: _statusColor(booking.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Penyewa: ${booking.renterEmail.isEmpty ? '-' : booking.renterEmail}',
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tanggal: ${booking.bookingDateText.isNotEmpty ? booking.bookingDateText : _formatDate(booking.bookingDate)}',
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jam: ${booking.bookingTime}',
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Durasi: ${booking.duration} jam',
            style: const TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
            ),
          ),
          if (booking.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${booking.note}',
              style: const TextStyle(
                color: AppColors.neutral,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Total: ${_formatRupiah(booking.totalPrice)}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(booking, 'rejected'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(booking, 'accepted'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Pesanan Masuk',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _venueService.getOwnerBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada pesanan masuk.',
                style: TextStyle(color: AppColors.neutral),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(bookings[index]);
            },
          );
        },
      ),
    );
  }
}
