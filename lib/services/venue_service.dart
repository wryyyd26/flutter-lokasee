import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue_model.dart';

class VenueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ambil semua venue (real-time dari Firestore)
  Stream<List<Venue>> getVenues() {
    return _db.collection('venues').snapshots().map((snapshot) {
      print('===== DEBUG VENUE SERVICE =====');
      print('Snapshot received: ${snapshot.docs.length} documents');

      final venues = snapshot.docs.map((doc) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');

        try {
          final venue = Venue.fromFirestore(doc.data(), doc.id);
          print('Successfully converted to Venue: ${venue.name}');
          return venue;
        } catch (e) {
          print('ERROR converting document: $e');
          rethrow;
        }
      }).toList();

      print('Total venues loaded: ${venues.length}');
      print('==============================');
      return venues;
    });
  }

  // Ambil venue berdasarkan kategori
  Stream<List<Venue>> getVenuesByCategory(String category) {
    return _db
        .collection('venues')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      print('Venues by category "$category": ${snapshot.docs.length}');
      return snapshot.docs.map((doc) {
        return Venue.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tambah venue baru
  Future<void> addVenue(Venue venue) async {
    await _db.collection('venues').add(venue.toMap());
  }

  // Tambah booking baru
  Future<void> addBooking(Booking booking) async {
    await _db.collection('bookings').add(booking.toMap());
  }
}
