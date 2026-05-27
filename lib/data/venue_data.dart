import '../models/venue_model.dart';

const List<String> venueCategories = [
  'Sport Town',
  'Dining Room',
  'Event Room',
];

const List<Venue> dummyVenues = [
  Venue(
    name: 'Futsal Arena Center',
    category: 'Sport Town',
    location: 'Jl. Merdeka No. 10',
    price: 'Rp 150.000 / jam',
    description:
        'Lapangan futsal indoor dengan rumput sintetis, pencahayaan terang, ruang tunggu, dan area parkir yang nyaman.',
    imageUrl: 'assets/images/futsal_arena.jpg',
  ),
  Venue(
    name: 'Badminton Hall Premium',
    category: 'Sport Town',
    location: 'Jl. Sudirman No. 21',
    price: 'Rp 90.000 / jam',
    description:
        'Hall badminton premium dengan lantai standar olahraga, ventilasi baik, dan fasilitas sewa raket.',
    imageUrl: 'assets/images/badminton_hall.jpg',
  ),
  Venue(
    name: 'Family Dining Room',
    category: 'Dining Room',
    location: 'Jl. Anggrek No. 5',
    price: 'Rp 350.000 / sesi',
    description:
        'Ruang makan keluarga privat dengan kapasitas hingga 12 orang, cocok untuk makan malam keluarga dan acara kecil.',
    imageUrl: 'assets/images/family_dining_room.jpg',
  ),
  Venue(
    name: 'Private Restaurant Room',
    category: 'Dining Room',
    location: 'Jl. Diponegoro No. 8',
    price: 'Rp 500.000 / sesi',
    description:
        'Ruang privat restoran dengan suasana eksklusif, cocok untuk meeting informal, ulang tahun, atau jamuan khusus.',
    imageUrl: 'assets/images/private_restaurant_room.jpg',
  ),
  Venue(
    name: 'Mini Event Hall',
    category: 'Event Room',
    location: 'Jl. Pahlawan No. 30',
    price: 'Rp 1.200.000 / hari',
    description:
        'Aula kecil untuk acara komunitas, workshop, ulang tahun, dan gathering dengan fasilitas kursi, meja, dan sound system.',
    imageUrl: 'assets/images/mini_event_hall.jpg',
  ),
  Venue(
    name: 'Meeting Room Creative',
    category: 'Event Room',
    location: 'Jl. Melati No. 14',
    price: 'Rp 250.000 / jam',
    description:
        'Ruang meeting modern dengan proyektor, papan tulis, Wi-Fi, dan desain nyaman untuk diskusi kreatif.',
    imageUrl: 'assets/images/meeting_room_creative.jpg',
  ),
];

String getCategoryIcon(String category) {
  switch (category) {
    case 'Sport Town':
      return 'assets/images/icon_sport.png';
    case 'Dining Room':
      return 'assets/images/icon_dining.png';
    case 'Event Room':
      return 'assets/images/icon_event.png';
    default:
      return 'assets/images/icon_sport.png';
  }
}
