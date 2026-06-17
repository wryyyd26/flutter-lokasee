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
  final int totalPrice;
  final String note;
  final String status;
  final DateTime? createdAt;

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
    required this.totalPrice,
    required this.note,
    required this.status,
    this.createdAt,
  });

  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      renterEmail: data['renterEmail'] ?? '',
      bookingDate: data['bookingDate'] is Timestamp
          ? (data['bookingDate'] as Timestamp).toDate()
          : null,
      bookingDateText: data['bookingDateText'] ?? '',
      bookingTime: data['bookingTime'] ?? '',
      duration: data['duration'] is int ? data['duration'] : 1,
      totalPrice: data['totalPrice'] is int ? data['totalPrice'] : 0,
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
