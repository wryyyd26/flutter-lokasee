import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_model.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final VenueService _venueService = VenueService();

  @override
  void initState() {
    super.initState();

    // Menandai notifikasi booking penyewa sebagai sudah dilihat
    _venueService.markAllRenterBookingsAsSeen();
  }

  bool _canCancel(String status) {
    return status == 'pending' ||
        status == 'pending_payment_verification' ||
        status == 'pending_offline_payment';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
    switch (status.toLowerCase()) {
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
        return Icons.remove_circle_rounded;
      case 'pending_payment_verification':
        return Icons.verified_user_rounded;
      case 'pending_offline_payment':
        return Icons.storefront_rounded;
      case 'pending':
      default:
        return Icons.access_time_filled_rounded;
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

  String _formatCurrency(int value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(value);
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan Booking?'),
          content: Text(
            'Apakah kamu yakin ingin membatalkan booking "${booking.venueName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _venueService.cancelBooking(booking.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibatalkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan booking: $e'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 82,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Booking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking venue yang kamu buat akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
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
          _InfoRow(
            icon: Icons.payments_rounded,
            label: 'Metode',
            value: _paymentMethodText(booking),
            valueColor: paymentColor,
            valueWeight: FontWeight.w900,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.verified_rounded,
            label: 'Status',
            value: _paymentStatusText(booking),
            valueColor: paymentColor,
            valueWeight: FontWeight.w900,
          ),
          if (isTransfer) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.account_balance_rounded,
              label: 'Bank',
              value: booking.bankName.isEmpty ? '-' : booking.bankName,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.credit_card_rounded,
              label: 'No. Rek',
              value: booking.bankAccountNumber.isEmpty
                  ? '-'
                  : booking.bankAccountNumber,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Atas Nama',
              value: booking.bankAccountName.isEmpty
                  ? '-'
                  : booking.bankAccountName,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 12),
            const Text(
              'Pembayaran dilakukan langsung di loket venue. Booking kamu akan menunggu konfirmasi owner.',
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
    final statusColor = _statusColor(booking.status);
    final statusText = _statusText(booking.status);
    final statusIcon = _statusIcon(booking.status);

    final canCancel = _canCancel(booking.status.toLowerCase());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header venue + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.venueName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.calendar_month_rounded,
              label: 'Tanggal',
              value: booking.bookingDateText,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Waktu',
              value: booking.bookingTime,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.timelapse_rounded,
              label: 'Durasi',
              value: booking.durationText.isNotEmpty
                  ? booking.durationText
                  : '${booking.duration} jam',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.payments_rounded,
              label: 'Total',
              value: _formatCurrency(booking.totalPrice),
            ),

            if (booking.note.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: booking.note,
              ),
            ],

            _buildPaymentSection(booking),

            if (canCancel) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _cancelBooking(booking),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text(
                    'Batalkan Booking',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
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
        centerTitle: true,
        title: const Text(
          'Booking Saya',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _venueService.getMyBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat booking:\n${snapshot.error}',
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

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return _buildBookingCard(bookings[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueWeight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueWeight,
              height: 1.35,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}