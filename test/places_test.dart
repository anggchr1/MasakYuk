import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/core/services/places_service.dart';

void main() {
  test('Overpass: pasar/toko dikenal, tanpa nama dibuang, dobel digabung',
      () {
    final list = PlacesService.dariJson({
      'elements': [
        {
          'type': 'node',
          'id': 1,
          'lat': -8.1750,
          'lon': 113.7030,
          'tags': {'name': 'Pasar Tanjung', 'amenity': 'marketplace'},
        },
        {
          // way: koordinat ada di center, bukan lat/lon
          'type': 'way',
          'id': 2,
          'center': {'lat': -8.1710, 'lon': 113.7020},
          'tags': {'name': 'Indomaret', 'shop': 'convenience'},
        },
        {
          'type': 'node',
          'id': 3,
          'lat': -8.1710,
          'lon': 113.7020,
          'tags': {'name': 'Indomaret', 'shop': 'convenience'},
        },
        {
          'type': 'node',
          'id': 4,
          'lat': -8.17,
          'lon': 113.70,
          'tags': {'shop': 'supermarket'},
        },
        {
          'type': 'node',
          'id': 5,
          'lat': -8.17,
          'lon': 113.70,
          'tags': {'name': 'Kios X', 'shop': 'kiosk'},
        },
      ],
    }, -8.1712, 113.7023);

    expect(list.length, 2);
    expect(list.first.nama, 'Indomaret'); // terdekat lebih dulu
    expect(list.first.id, 'osm-way-2');
    expect(list.first.jenis, 'Pasar');
    expect(list.first.alamat, 'Sekitar lokasi Anda');
    expect(list.first.rating, 0);
    expect(list.last.nama, 'Pasar Tanjung');
    expect(list.last.jenis, 'Pasar');
  });

  test('Nominatim: nama kosong dibuang, jenis & jalan terbaca', () {
    final list = PlacesService.dariNominatim([
      {
        'osm_type': 'node',
        'osm_id': 9,
        'lat': '-8.1761',
        'lon': '113.7006',
        'name': 'Warung Rujak',
        'address': {
          'road': 'Jalan WR Supratman III',
          'house_number': '21',
          'village': 'Tegal Besar',
          'city': 'Jember',
        },
        'extratags': {
          'opening_hours': 'Mo-Su 08:00-20:00',
          'phone': '+62 812-3456-7890',
          'website': 'https://warungrujak.id',
          'takeaway': 'yes',
        },
      },
      {
        'osm_type': 'node',
        'osm_id': 10,
        'lat': '-8.1',
        'lon': '113.7',
        'name': '',
      },
    ], 'Warung Makan');

    expect(list.length, 1);
    expect(list.first.nama, 'Warung Rujak');
    expect(list.first.jenis, 'Warung Makan');
    expect(list.first.alamat,
        'Jalan WR Supratman III 21, Tegal Besar, Jember');
    expect(list.first.jam, 'Mo-Su 08:00-20:00');
    expect(list.first.telepon, '+62 812-3456-7890');
    expect(list.first.situs, 'https://warungrujak.id');
    expect(list.first.fasilitas, ['Bisa dibawa pulang']);
  });

  test('Nominatim: rumah sakit & pasar non-bahan dibuang', () {
    final makan = PlacesService.dariNominatim([
      {
        'osm_type': 'node',
        'osm_id': 1,
        'lat': '-7.596',
        'lon': '111.896',
        'name': 'RS. Bhayangkara TK. III',
      },
      {
        'osm_type': 'node',
        'osm_id': 2,
        'lat': '-7.606',
        'lon': '111.902',
        'name': 'Soto Ayam Mbak Mar',
      },
    ], 'Rumah Makan');
    expect(makan.map((p) => p.nama), ['Soto Ayam Mbak Mar']);

    final pasar = PlacesService.dariNominatim([
      {
        'osm_type': 'node',
        'osm_id': 3,
        'lat': '-7.610',
        'lon': '111.902',
        'name': 'Pasar Sepeda (Traditional Bicycle Market)',
      },
      {
        'osm_type': 'node',
        'osm_id': 4,
        'lat': '-7.608',
        'lon': '111.899',
        'name': 'Pasar Wage Nganjuk',
      },
    ], 'Pasar');
    expect(pasar.map((p) => p.nama), ['Pasar Wage Nganjuk']);
  });
}
