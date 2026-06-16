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

  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.rating = 0.0,
  });

  // Konversi dari Firestore document ke object Venue
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
    );
  }

  // Konversi dari object ke Map (untuk simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}

class Booking {
  final String id;
  final String userId;
  final String venueId;
  final String venueName;
  final DateTime bookingDate;
  final String bookingTime;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.venueName,
    required this.bookingDate,
    required this.bookingTime,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      userId: data['userId'] ?? '',
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      bookingTime: data['bookingTime'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'venueId': venueId,
      'venueName': venueName,
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
