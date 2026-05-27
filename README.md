# Lokasee Flutter Prototype

Prototype aplikasi pemesanan venue sesuai PRD Progress 1. Fokus project ini adalah UI, struktur folder, navigasi, animasi, dan data statis.

## Update UI Smooth / Agoda-like

Versi ini sudah ditingkatkan agar tidak terlalu kaku:

- Layout Home lebih mirip aplikasi booking/travel modern.
- Category dibuat horizontal card/chip seperti aplikasi listing.
- Card venue dibuat lebih besar dengan badge rating, harga, dan CTA detail.
- Transisi halaman memakai custom fade + slide route.
- Card punya efek press/scale saat diklik.
- Konten masuk memakai animasi fade + slide.
- Detail venue memakai Hero animation dari card ke halaman detail.
- Form owner dibuat lebih modern dengan hero header dan animated field.

## Warna

- Primary: `#172A39`
- Background: `#E9E4E0`
- Accent: `#FC563C`
- Neutral: `#6E7575`

## File Mockup

- `design/lokasee_ui_mockup_overview.png`
- `design/lokasee_animation_motion_spec.png`
- `design/lokasee_color_palette.png`

## Cara Menjalankan

```bash
cd lokasee_flutter
flutter create .
flutter pub get
flutter run
```

## Catatan

Project ini belum memakai Firebase, database, upload gambar, pembayaran, atau booking asli. Semua data masih statis sesuai target Progress 1.
