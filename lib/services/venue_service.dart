import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import '../models/venue_model.dart';

class VenueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // VENUE
  // =========================

  // Ambil semua venue real-time dari Firestore
  Stream<List<Venue>> getVenues() {
    return _db.collection('venues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venue.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ambil venue berdasarkan kategori
  Stream<List<Venue>> getVenuesByCategory(String category) {
    return _db
        .collection('venues')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venue.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tambah venue baru
  Future<void> addVenue(Venue venue) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    await _db.collection('venues').add({
      ...venue.toMap(),
      'ownerId': venue.ownerId.isNotEmpty ? venue.ownerId : currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // BOOKING HELPER
  // =========================

  DateTime _onlyDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameOnlyDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _parseBookingDate(dynamic value) {
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

  int _timeToMinutes(String time) {
    final cleanTime = time.trim();

    if (cleanTime.toLowerCase().contains('full day')) {
      return 0;
    }

    final parts = cleanTime.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return (hour * 60) + minute;
  }

  bool _isTimeOverlap({
    required int newStart,
    required int newEnd,
    required int existingStart,
    required int existingEnd,
  }) {
    return newStart < existingEnd && existingStart < newEnd;
  }

  Future<bool> _isBookingScheduleConflict({
    required String venueId,
    required DateTime bookingDate,
    required String bookingTime,
    required int duration,
    required bool isFullDay,
  }) async {
    final snapshot = await _db
        .collection('bookings')
        .where('venueId', isEqualTo: venueId)
        .where(
      'status',
      whereIn: [
        'pending',
        'pending_payment_verification',
        'pending_offline_payment',
        'accepted',
      ],
    ).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final existingDate = _parseBookingDate(data['bookingDate']);

      if (existingDate == null) {
        continue;
      }

      if (!_isSameOnlyDate(existingDate, bookingDate)) {
        continue;
      }

      final existingBookingTime = (data['bookingTime'] ?? '').toString();

      final existingDuration = data['duration'] is int
          ? data['duration'] as int
          : int.tryParse('${data['duration'] ?? 1}') ?? 1;

      final existingIsFullDay =
          existingBookingTime.toLowerCase().contains('full day');

      // Kalau booking baru full day,
      // semua booking aktif di tanggal yang sama dianggap bentrok.
      if (isFullDay) {
        return true;
      }

      // Kalau booking lama full day,
      // booking baru jam berapa pun di tanggal yang sama tetap bentrok.
      if (existingIsFullDay) {
        return true;
      }

      final newStart = _timeToMinutes(bookingTime);
      final newEnd = newStart + (duration * 60);

      final existingStart = _timeToMinutes(existingBookingTime);
      final existingEnd = existingStart + (existingDuration * 60);

      final isOverlap = _isTimeOverlap(
        newStart: newStart,
        newEnd: newEnd,
        existingStart: existingStart,
        existingEnd: existingEnd,
      );

      if (isOverlap) {
        return true;
      }
    }

    return false;
  }

  String _normalizePaymentMethod(String paymentMethod) {
    final method = paymentMethod.trim().toLowerCase();

    if (method == 'transfer') {
      return 'transfer';
    }

    if (method == 'offline') {
      return 'offline';
    }

    throw Exception('Metode pembayaran tidak valid.');
  }

  String _initialBookingStatusByPaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'transfer':
        return 'pending_payment_verification';
      case 'offline':
        return 'pending_offline_payment';
      default:
        return 'pending';
    }
  }

  String _initialPaymentStatusByPaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'transfer':
        return 'waiting_verification';
      case 'offline':
        return 'unpaid_offline';
      default:
        return 'unknown';
    }
  }

  // =========================
  // CREATE BOOKING
  // =========================

  // Buat booking baru dari user penyewa
  Future<void> createBooking({
    required Venue venue,
    required DateTime bookingDate,
    required String bookingDateText,
    required String bookingTime,
    required int duration,
    required int totalPrice,
    required String paymentMethod,
    String durationText = '',
    String note = '',
    String paymentProofUrl = '',
    String bankName = 'BCA',
    String bankAccountNumber = '1234567890',
    String bankAccountName = 'Lokasee Venue',
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    if (venue.id.isEmpty) {
      throw Exception('Venue tidak valid.');
    }

    if (venue.ownerId.isEmpty) {
      throw Exception('Venue belum memiliki ownerId.');
    }

    if (venue.ownerId == currentUser.uid) {
      throw Exception('Owner tidak bisa booking venue miliknya sendiri.');
    }

    final cleanPaymentMethod = _normalizePaymentMethod(paymentMethod);
    final cleanPaymentProofUrl = paymentProofUrl.trim();

    if (cleanPaymentMethod == 'transfer' && cleanPaymentProofUrl.isEmpty) {
      throw Exception('Bukti transfer wajib diupload.');
    }

    final isFullDay = bookingTime.toLowerCase().contains('full day');

    final hasConflict = await _isBookingScheduleConflict(
      venueId: venue.id,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      duration: duration,
      isFullDay: isFullDay,
    );

    if (hasConflict) {
      throw Exception(
        'Jadwal bentrok. Slot ini sudah dipesan atau sedang menunggu persetujuan.',
      );
    }

    final cleanDurationText =
        durationText.trim().isEmpty ? '$duration jam' : durationText.trim();

    final initialStatus = _initialBookingStatusByPaymentMethod(
      cleanPaymentMethod,
    );

    final initialPaymentStatus = _initialPaymentStatusByPaymentMethod(
      cleanPaymentMethod,
    );

    await _db.collection('bookings').add({
      'venueId': venue.id,
      'venueName': venue.name,
      'venueImageUrl': venue.imageUrl,
      'venueCategory': venue.category,
      'venueLocation': venue.location,

      'ownerId': venue.ownerId,

      'renterId': currentUser.uid,
      'renterEmail': currentUser.email ?? '',
      'renterName': currentUser.displayName ?? '',

      'bookingDate': Timestamp.fromDate(_onlyDate(bookingDate)),
      'bookingDateText': bookingDateText,
      'bookingTime': bookingTime,

      'duration': duration,
      'durationText': cleanDurationText,
      'totalPrice': totalPrice,
      'note': note.trim(),

      // Payment
      'paymentMethod': cleanPaymentMethod,
      'paymentStatus': initialPaymentStatus,
      'paymentProofUrl': cleanPaymentProofUrl,
      'bankName': bankName.trim(),
      'bankAccountNumber': bankAccountNumber.trim(),
      'bankAccountName': bankAccountName.trim(),

      // Status awal booking berdasarkan metode pembayaran
      'status': initialStatus,

      // Penyewa baru saja membuat booking,
      // jadi tidak perlu notifikasi baru untuk dirinya sendiri.
      'isSeenByRenter': true,

      // Owner belum melihat pesanan baru.
      'isSeenByOwner': false,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // OWNER BOOKING
  // =========================

  // Ambil booking yang masuk ke owner yang sedang login
  Stream<List<BookingModel>> getOwnerBookings() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value([]);
    }

    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        return BookingModel.fromFirestore(doc.data(), doc.id);
      }).toList();

      bookings.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return bookings;
    });
  }

  // Ambil jumlah pesanan baru yang belum dilihat owner
  Stream<int> getUnreadOwnerBookingCount() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(0);
    }

    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('isSeenByOwner', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Tandai semua pesanan masuk owner sebagai sudah dilihat
  Future<void> markAllOwnerBookingsAsSeen() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final snapshot = await _db
        .collection('bookings')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('isSeenByOwner', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSeenByOwner': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Update status booking: accepted / rejected / cancelled
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final allowedStatuses = [
      'accepted',
      'rejected',
      'cancelled',
    ];

    if (!allowedStatuses.contains(status)) {
      throw Exception('Status booking tidak valid.');
    }

    final bookingRef = _db.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception('Booking tidak ditemukan.');
    }

    final data = bookingDoc.data();

    if (data == null) {
      throw Exception('Data booking tidak valid.');
    }

    final ownerId = data['ownerId'] ?? '';

    if (ownerId != currentUser.uid) {
      throw Exception('Kamu tidak memiliki akses untuk mengubah booking ini.');
    }

    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),

      // Owner sudah melakukan aksi.
      'isSeenByOwner': true,

      // Penyewa perlu dapat notifikasi baru.
      'isSeenByRenter': false,
    };

    if (status == 'accepted') {
      updateData['paymentStatus'] = 'verified';
    }

    if (status == 'rejected') {
      updateData['paymentStatus'] = 'rejected';
    }

    await bookingRef.update(updateData);
  }

  // =========================
  // RENTER BOOKING
  // =========================

  // Ambil booking milik penyewa/user yang sedang login
  Stream<List<BookingModel>> getMyBookings() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value([]);
    }

    return _db
        .collection('bookings')
        .where('renterId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        return BookingModel.fromFirestore(doc.data(), doc.id);
      }).toList();

      bookings.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return bookings;
    });
  }

  // Ambil jumlah notifikasi booking penyewa yang belum dilihat
  Stream<int> getUnreadRenterNotificationCount() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(0);
    }

    return _db
        .collection('bookings')
        .where('renterId', isEqualTo: currentUser.uid)
        .where('isSeenByRenter', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Tandai 1 booking sebagai sudah dilihat oleh penyewa
  Future<void> markBookingAsSeenByRenter(String bookingId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final bookingRef = _db.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception('Booking tidak ditemukan.');
    }

    final data = bookingDoc.data();

    if (data == null) {
      throw Exception('Data booking tidak valid.');
    }

    final renterId = data['renterId'] ?? '';

    if (renterId != currentUser.uid) {
      throw Exception('Kamu tidak memiliki akses ke booking ini.');
    }

    await bookingRef.update({
      'isSeenByRenter': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tandai semua notifikasi booking penyewa sebagai sudah dilihat
  Future<void> markAllRenterBookingsAsSeen() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final snapshot = await _db
        .collection('bookings')
        .where('renterId', isEqualTo: currentUser.uid)
        .where('isSeenByRenter', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSeenByRenter': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Batalkan booking oleh penyewa
  Future<void> cancelBooking(String bookingId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final bookingRef = _db.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception('Booking tidak ditemukan.');
    }

    final data = bookingDoc.data();

    if (data == null) {
      throw Exception('Data booking tidak valid.');
    }

    final renterId = data['renterId'] ?? '';
    final status = data['status'] ?? '';

    if (renterId != currentUser.uid) {
      throw Exception(
        'Kamu tidak memiliki akses untuk membatalkan booking ini.',
      );
    }

    final cancellableStatuses = [
      'pending',
      'pending_payment_verification',
      'pending_offline_payment',
    ];

    if (!cancellableStatuses.contains(status)) {
      throw Exception(
        'Booking hanya bisa dibatalkan saat masih menunggu persetujuan.',
      );
    }

    await bookingRef.update({
      'status': 'cancelled',
      'paymentStatus': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),

      // Owner perlu tahu kalau penyewa membatalkan booking.
      'isSeenByOwner': false,

      // Penyewa sendiri sudah tahu karena dia yang membatalkan.
      'isSeenByRenter': true,
    });
  }
}
