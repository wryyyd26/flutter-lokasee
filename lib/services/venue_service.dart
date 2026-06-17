import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import '../models/venue_model.dart';

class VenueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    await _db.collection('venues').add({
      ...venue.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Buat booking baru dari user penyewa
  Future<void> createBooking({
    required Venue venue,
    required DateTime bookingDate,
    required String bookingDateText,
    required String bookingTime,
    required int duration,
    required int totalPrice,
    String durationText = '',
    String note = '',
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    if (venue.ownerId.isEmpty) {
      throw Exception('Venue belum memiliki ownerId.');
    }

    if (venue.ownerId == currentUser.uid) {
      throw Exception('Owner tidak bisa booking venue miliknya sendiri.');
    }

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

      'bookingDate': Timestamp.fromDate(
        DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
        ),
      ),
      'bookingDateText': bookingDateText,
      'bookingTime': bookingTime,

      'duration': duration,
      'durationText': durationText.isEmpty ? '$duration jam' : durationText,
      'totalPrice': totalPrice,
      'note': note.trim(),

      // Status awal booking
      'status': 'pending',

      // Untuk notifikasi penyewa
      // true karena penyewa baru saja membuat booking, jadi belum perlu dianggap notifikasi baru
      'isSeenByRenter': true,

      // Untuk owner
      // false karena owner belum melihat pesanan baru ini
      'isSeenByOwner': false,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Ambil booking yang masuk ke owner yang sedang login
  Stream<List<BookingModel>> getOwnerBookings() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
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

  // Ambil booking milik penyewa/user yang sedang login
  Stream<List<BookingModel>> getMyBookings() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
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
      return const Stream.empty();
    }

    return _db
        .collection('bookings')
        .where('renterId', isEqualTo: currentUser.uid)
        .where('isSeenByRenter', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Ambil jumlah pesanan baru yang belum dilihat owner
  Stream<int> getUnreadOwnerBookingCount() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('isSeenByOwner', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Update status booking: pending / accepted / rejected / cancelled
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    if (status != 'pending' &&
        status != 'accepted' &&
        status != 'rejected' &&
        status != 'cancelled') {
      throw Exception('Status booking tidak valid.');
    }

    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),

      // Kalau owner sudah acc/tolak, penyewa perlu dapat notifikasi baru
      if (status == 'accepted' || status == 'rejected') 'isSeenByRenter': false,

      // Owner sudah melakukan aksi, jadi pesanan dianggap sudah dilihat owner
      'isSeenByOwner': true,
    });
  }

  // Tandai 1 booking sebagai sudah dilihat oleh penyewa
  Future<void> markBookingAsSeenByRenter(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isSeenByRenter': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tandai semua notifikasi booking penyewa sebagai sudah dilihat
  Future<void> markAllRenterBookingsAsSeen() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final snapshot = await _db
        .collection('bookings')
        .where('renterId', isEqualTo: currentUser.uid)
        .where('isSeenByRenter', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSeenByRenter': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Tandai semua pesanan masuk owner sebagai sudah dilihat
  Future<void> markAllOwnerBookingsAsSeen() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final snapshot = await _db
        .collection('bookings')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('isSeenByOwner', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSeenByOwner': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Batalkan booking oleh penyewa
  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'isSeenByOwner': false,
    });
  }
}
