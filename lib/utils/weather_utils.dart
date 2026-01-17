String weatherEmoji(String weather) {
  final w = weather.toLowerCase();
  if (w.contains('sun') || w.contains('ensoleil') || w.contains('soleil') || w.contains('☀')) return '☀️';
  if (w.contains('cloud') || w.contains('nuage') || w.contains('⛅')) return '⛅';
  if (w.contains('rain') || w.contains('pluie') || w.contains('pluv') || w.contains('🌧')) return '🌧️';
  if (w.contains('storm') || w.contains('orage') || w.contains('⛈') || w.contains('orageux')) return '🌩️';
  if (w.contains('snow') || w.contains('neige') || w.contains('❄')) return '❄️';
  return '🌤️';
}

// Petit utilitaire pour normaliser les libellés météo
String normalizeWeatherLabel(String weather) {
  return weather.trim();
}
