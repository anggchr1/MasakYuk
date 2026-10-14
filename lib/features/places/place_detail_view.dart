import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/know.dart';

/// Detail tempat: info + tombol Rute (deep link Maps gratis, tanpa API key).
class PlaceDetailScreen extends StatelessWidget {
  final PlaceInfo place;
  const PlaceDetailScreen(
      {super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.nama)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            color: AppColors.primaryContainer,
            child: Center(
              child: Text(
                place.nama.isEmpty ? '?' : place.nama[0],
                style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(place.jenis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star,
                        size: 16, color: AppColors.amber),
                    Text(
                        ' ${place.rating} (${place.ulasan} ulasan)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(place.nama,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.chocolate)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16,
                        color: AppColors.chocolateMuted),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(place.alamat,
                            style: const TextStyle(
                                color: AppColors
                                    .chocolateMuted))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${place.harga} • ${place.hargaNote}',
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(place.desc,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6)),
                if (place.contoh) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Data contoh untuk demo — diganti data live belakangan.',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.chocolateMuted),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}&travelmode=driving'),
                      mode:
                          LaunchMode.externalApplication,
                    ),
                    icon: const Icon(
                        Icons.directions_outlined),
                    label:
                        const Text('Rute di Google Maps'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
