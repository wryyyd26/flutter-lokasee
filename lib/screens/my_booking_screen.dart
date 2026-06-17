import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;

  final String venueId;
  final String venueName;
  final String venueImageUrl;
  final String venueCategory;
  final String venueLocation;

  final String ownerId;

  final String renterId;
  final String renterEmail;
  final String renterName;

  final DateTime bookingDate;
  final String bookingDateText;
  final String bookingTime;

  final int duration;
  final String durationText;
  final int totalPrice;
  final String note;

  final String status;

  final bool isSeenByRenter;
  final bool isSeenByOwner;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? statusUpdatedAt;

  const BookingModel({
    required this.id,
    required this.venueId,
    required this.venueName,
    this.venueImageUrl = '',
    this.venueCategory = '',
    this.venueLocation = '',
    required this.ownerId,
    required this.renterId,
    required this.renterEmail,
    this.renterName = '',
    required this.bookingDate,
    required this.bookingDateText,
    required this.bookingTime,
    required this.duration,
    required this.durationText,
    required this.totalPrice,
    required this.note,
    required this.status,
    this.isSeenByRenter = true,
    this.isSeenByOwner = false,
    this.createdAt,
    this.updatedAt,
    this.statusUpdatedAt,
  });

  static DateTime? _toNullableDateTime(dynamic value) {
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

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return defaultValue;
  }

  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    final parsedBookingDate = _toNullableDateTime(data['bookingDate']);

    return BookingModel(
      id: id,
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueImageUrl: data['venueImageUrl'] ?? '',
      venueCategory: data['venueCategory'] ?? '',
      venueLocation: data['venueLocation'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      renterEmail: data['renterEmail'] ?? '',
      renterName: data['renterName'] ?? '',
      bookingDate: parsedBookingDate ?? DateTime.now(),
      bookingDateText: data['bookingDateText'] ?? '',
      bookingTime: data['bookingTime'] ?? '',
      duration: _toInt(data['duration'], defaultValue: 1),
      durationText: data['durationText'] ??
          '${_toInt(data['duration'], defaultValue: 1)} jam',
      totalPrice: _toInt(data['totalPrice'], defaultValue: 0),
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',
      isSeenByRenter: _toBool(
        data['isSeenByRenter'],
        defaultValue: true,
      ),
      isSeenByOwner: _toBool(
        data['isSeenByOwner'],
        defaultValue: false,
      ),
      createdAt: _toNullableDateTime(data['createdAt']),
      updatedAt: _toNullableDateTime(data['updatedAt']),
      statusUpdatedAt: _toNullableDateTime(data['statusUpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'venueName': venueName,
      'venueImageUrl': venueImageUrl,
      'venueCategory': venueCategory,
      'venueLocation': venueLocation,
      'ownerId': ownerId,
      'renterId': renterId,
      'renterEmail': renterEmail,
      'renterName': renterName,
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
      'durationText': durationText,
      'totalPrice': totalPrice,
      'note': note,
      'status': status,
      'isSeenByRenter': isSeenByRenter,
      'isSeenByOwner': isSeenByOwner,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedAt': statusUpdatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(statusUpdatedAt!),
    };
  }

  BookingModel copyWith({
    String? id,
    String? venueId,
    String? venueName,
    String? venueImageUrl,
    String? venueCategory,
    String? venueLocation,
    String? ownerId,
    String? renterId,
    String? renterEmail,
    String? renterName,
    DateTime? bookingDate,
    String? bookingDateText,
    String? bookingTime,
    int? duration,
    String? durationText,
    int? totalPrice,
    String? note,
    String? status,
    bool? isSeenByRenter,
    bool? isSeenByOwner,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? statusUpdatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueImageUrl: venueImageUrl ?? this.venueImageUrl,
      venueCategory: venueCategory ?? this.venueCategory,
      venueLocation: venueLocation ?? this.venueLocation,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      renterEmail: renterEmail ?? this.renterEmail,
      renterName: renterName ?? this.renterName,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingDateText: bookingDateText ?? this.bookingDateText,
      bookingTime: bookingTime ?? this.bookingTime,
      duration: duration ?? this.duration,
      durationText: durationText ?? this.durationText,
      totalPrice: totalPrice ?? this.totalPrice,
      note: note ?? this.note,
      status: status ?? this.status,
      isSeenByRenter: isSeenByRenter ?? this.isSeenByRenter,
      isSeenByOwner: isSeenByOwner ?? this.isSeenByOwner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }
}
