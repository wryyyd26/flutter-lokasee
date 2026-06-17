import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String venueId;
  final String venueName;
  final String ownerId;
  final String renterId;
  final String renterEmail;

  final DateTime? bookingDate;
  final String bookingDateText;
  final String bookingTime;
  final int duration;
  final String durationText;

  final int totalPrice;
  final String note;
  final String status;

  // Payment fields
  final String paymentMethod;
  final String paymentStatus;
  final String paymentProofUrl;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  // Notification fields
  final bool seenByRenter;
  final bool seenByOwner;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? statusUpdatedAt;

  const BookingModel({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.ownerId,
    required this.renterId,
    required this.renterEmail,
    this.bookingDate,
    required this.bookingDateText,
    required this.bookingTime,
    required this.duration,
    required this.durationText,
    required this.totalPrice,
    required this.note,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentProofUrl,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.seenByRenter,
    required this.seenByOwner,
    this.createdAt,
    this.updatedAt,
    this.statusUpdatedAt,
  });

  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }

      return null;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse('${value ?? 0}') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    final duration = parseInt(data['duration']);
    final durationText = (data['durationText'] ?? '').toString().trim();

    final paymentMethod = (data['paymentMethod'] ?? '').toString().trim();
    final paymentStatus = (data['paymentStatus'] ?? '').toString().trim();

    return BookingModel(
      id: id,
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      renterEmail: data['renterEmail'] ?? '',

      bookingDate: parseDate(data['bookingDate']),
      bookingDateText: data['bookingDateText'] ?? '',
      bookingTime: data['bookingTime'] ?? '',
      duration: duration,
      durationText: durationText.isNotEmpty ? durationText : '$duration jam',

      totalPrice: parseInt(data['totalPrice']),
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',

      // Kalau data lama belum punya paymentMethod,
      // otomatis dianggap offline supaya tidak error.
      paymentMethod: paymentMethod.isNotEmpty ? paymentMethod : 'offline',
      paymentStatus:
          paymentStatus.isNotEmpty ? paymentStatus : 'unpaid_offline',
      paymentProofUrl: data['paymentProofUrl'] ?? '',
      bankName: data['bankName'] ?? '',
      bankAccountNumber: data['bankAccountNumber'] ?? '',
      bankAccountName: data['bankAccountName'] ?? '',

      // Support field lama dan field baru.
      // Service kamu sekarang pakai isSeenByRenter/isSeenByOwner.
      seenByRenter: parseBool(
        data['isSeenByRenter'] ?? data['seenByRenter'] ?? false,
      ),
      seenByOwner: parseBool(
        data['isSeenByOwner'] ?? data['seenByOwner'] ?? false,
      ),

      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      statusUpdatedAt: parseDate(data['statusUpdatedAt']),
    );
  }

  bool get isTransferPayment {
    return paymentMethod == 'transfer';
  }

  bool get isOfflinePayment {
    return paymentMethod == 'offline';
  }

  bool get hasPaymentProof {
    return paymentProofUrl.trim().isNotEmpty;
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'transfer':
        return 'Transfer Bank';
      case 'offline':
        return 'Bayar Offline di Loket';
      default:
        return 'Belum dipilih';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'waiting_verification':
        return 'Menunggu Verifikasi Pembayaran';
      case 'unpaid_offline':
        return 'Bayar Offline di Loket';
      case 'verified':
        return 'Pembayaran Terverifikasi';
      case 'rejected':
        return 'Pembayaran Ditolak';
      default:
        return 'Status Pembayaran Tidak Diketahui';
    }
  }

  String get statusText {
    switch (status) {
      case 'pending_payment_verification':
        return 'Menunggu Verifikasi Pembayaran';
      case 'pending_offline_payment':
        return 'Menunggu Pembayaran Offline';
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'accepted':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
