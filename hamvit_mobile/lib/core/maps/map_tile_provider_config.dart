class MapTileProviderConfig {
  final String urlTemplate;
  final String userAgentPackageName;
  final String attribution;

  const MapTileProviderConfig({
    required this.urlTemplate,
    required this.userAgentPackageName,
    required this.attribution,
  });

  static const osm = MapTileProviderConfig(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.hamvit.mobile',
    attribution: '© OpenStreetMap contributors',
  );
}
