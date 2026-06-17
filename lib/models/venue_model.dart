import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String category;
  final String location;
  final String price;
  final String description;
  final String imageUrl;
  final double rating;
  final String ownerId;
  final double? latitude;
  final double? longitude;

  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.rating = 0.0,
    this.ownerId = '',
    this.latitude,
    this.longitude,
  });

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  factory Venue.fromFirestore(Map<String, dynamic> data, String id) {
    return Venue(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      price: data['price'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      ownerId: data['ownerId'] ?? '',
      latitude: _toNullableDouble(data['latitude']),
      longitude: _toNullableDouble(data['longitude']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'ownerId': ownerId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Booking {
  final String id;
  final String renterId;
  final String renterEmail;
  final String ownerId;
  final String venueId;
  final String venueName;
  final DateTime bookingDate;
  final String bookingTime;
  final String durationText;
  final int duration;
  final int totalPrice;
  final String note;
  final String status;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.renterId,
    required this.renterEmail,
    required this.ownerId,
    required this.venueId,
    required this.venueName,
    required this.bookingDate,
    required this.bookingTime,
    required this.durationText,
    required this.duration,
    required this.totalPrice,
    required this.note,
    this.status = 'pending',
    this.createdAt,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      renterId: data['renterId'] ?? '',
      renterEmail: data['renterEmail'] ?? '',
      ownerId: data['ownerId'] ?? '',
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      bookingDate: data['bookingDate'] is Timestamp
          ? (data['bookingDate'] as Timestamp).toDate()
          : DateTime.now(),
      bookingTime: data['bookingTime'] ?? '',
      durationText: data['durationText'] ?? '',
      duration: data['duration'] ?? 1,
      totalPrice: data['totalPrice'] ?? 0,
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'renterId': renterId,
      'renterEmail': renterEmail,
      'ownerId': ownerId,
      'venueId': venueId,
      'venueName': venueName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': bookingTime,
      'durationText': durationText,
      'duration': duration,
      'totalPrice': totalPrice,
      'note': note,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
