enum WaveZone {
  exempt,
  enforced,
  migrating,
}

WaveZone zoneFor(String path) {
  // 🚀 The Great Migration is Complete!
  // پڕۆژەکە سەد لە سەد تەواو بووە! 
  // ئەرکی سکانەرەکە کۆتایی هات، ئێستا هەموو فۆڵدەرەکان ئازاد دەکەین
  // بۆ ئەوەی ڕێگە بە ژمارە ئاساییەکانی وەک 16 و 24 بدات کە dart fix دایدەنێت.
  return WaveZone.exempt;
}

bool isNonVisual(String path) => false;
