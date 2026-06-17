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

  @override
  void initState() {
    super.initState();
    _venueService.markAllOwnerBookingsAsSeen();
  }

  bool _isActionableStatus(String status) {
    return status == 'pending' ||
        status == 'pending_payment_verification' ||
        status == 'pending_offline_payment';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'pending_payment_verification':
        return Colors.deepOrange;
      case 'pending_offline_payment':
        return Colors.blue;
      case 'pending':
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
      case 'pending_payment_verification':
        return 'Menunggu Verifikasi Pembayaran';
      case 'pending_offline_payment':
        return 'Menunggu Pembayaran Offline';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  Color _paymentColor(String paymentMethod) {
    switch (paymentMethod) {
      case 'transfer':
        return Colors.deepPurple;
      case 'offline':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _paymentMethodText(BookingModel booking) {
    if (booking.paymentMethodText.isNotEmpty) {
      return booking.paymentMethodText;
    }

    switch (booking.paymentMethod) {
      case 'transfer':
        return 'Transfer Bank';
      case 'offline':
        return 'Bayar Offline di Loket';
      default:
        return 'Belum dipilih';
    }
  }

  String _paymentStatusText(BookingModel booking) {
    if (booking.paymentStatusText.isNotEmpty) {
      return booking.paymentStatusText;
    }

    switch (booking.paymentStatus) {
      case 'waiting_verification':
        return 'Menunggu Verifikasi Pembayaran';
      case 'unpaid_offline':
        return 'Bayar Offline di Loket';
      case 'verified':
        return 'Pembayaran Terverifikasi';
      case 'rejected':
        return 'Pembayaran Ditolak';
      case 'cancelled':
        return 'Pembayaran Dibatalkan';
      default:
        return '-';
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

  void _showPaymentProof(BookingModel booking) {
    final proofUrl = booking.paymentProofUrl.trim();

    if (proofUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti transfer belum tersedia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bukti Transfer',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(14),
                  child: Image.network(
                    proofUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return const SizedBox(
                        height: 280,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 220,
                        child: Center(
                          child: Text(
                            'Gagal memuat gambar bukti transfer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight valueWeight = FontWeight.w700,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor ?? AppColors.primary,
                fontSize: 13,
                height: 1.35,
                fontWeight: valueWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BookingModel booking) {
    final isTransfer = booking.paymentMethod == 'transfer';
    final paymentColor = _paymentColor(booking.paymentMethod);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paymentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: paymentColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pembayaran',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.payments_rounded,
            label: 'Metode',
            value: _paymentMethodText(booking),
            valueColor: paymentColor,
            valueWeight: FontWeight.w900,
          ),
          _infoRow(
            icon: Icons.verified_rounded,
            label: 'Status',
            value: _paymentStatusText(booking),
            valueColor: paymentColor,
            valueWeight: FontWeight.w900,
          ),
          if (isTransfer) ...[
            _infoRow(
              icon: Icons.account_balance_rounded,
              label: 'Bank',
              value: booking.bankName.isEmpty ? '-' : booking.bankName,
            ),
            _infoRow(
              icon: Icons.credit_card_rounded,
              label: 'No. Rek',
              value: booking.bankAccountNumber.isEmpty
                  ? '-'
                  : booking.bankAccountNumber,
            ),
            _infoRow(
              icon: Icons.person_rounded,
              label: 'Atas Nama',
              value: booking.bankAccountName.isEmpty
                  ? '-'
                  : booking.bankAccountName,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: booking.paymentProofUrl.trim().isEmpty
                    ? null
                    : () => _showPaymentProof(booking),
                icon: const Icon(Icons.image_rounded),
                label: Text(
                  booking.paymentProofUrl.trim().isEmpty
                      ? 'Bukti Transfer Belum Ada'
                      : 'Lihat Bukti Transfer',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: paymentColor,
                  side: BorderSide(color: paymentColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              'Penyewa memilih pembayaran langsung di loket venue. Pastikan pembayaran dikonfirmasi saat penyewa datang.',
              style: TextStyle(
                color: AppColors.neutral,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isActionable = _isActionableStatus(booking.status);
    final durationText = booking.durationText.isNotEmpty
        ? booking.durationText
        : '${booking.duration} jam';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
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
                  color: _statusColor(booking.status).withValues(alpha: 0.12),
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
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.email_rounded,
            label: 'Penyewa',
            value: booking.renterEmail.isEmpty ? '-' : booking.renterEmail,
          ),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Tanggal',
            value: booking.bookingDateText.isNotEmpty
                ? booking.bookingDateText
                : _formatDate(booking.bookingDate),
          ),
          _infoRow(
            icon: Icons.access_time_rounded,
            label: 'Jam',
            value: booking.bookingTime,
          ),
          _infoRow(
            icon: Icons.timelapse_rounded,
            label: 'Durasi',
            value: durationText,
          ),
          if (booking.note.isNotEmpty)
            _infoRow(
              icon: Icons.notes_rounded,
              label: 'Catatan',
              value: booking.note,
            ),
          const SizedBox(height: 4),
          _infoRow(
            icon: Icons.attach_money_rounded,
            label: 'Total',
            value: _formatRupiah(booking.totalPrice),
            valueColor: AppColors.accent,
            valueWeight: FontWeight.w900,
          ),
          _buildPaymentSection(booking),
          if (isActionable) ...[
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Belum ada pesanan masuk.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.neutral,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            return _buildEmptyState();
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
