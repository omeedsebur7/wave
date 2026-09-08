/// Hero tags live in one place so a source and its destination cannot drift.
///
/// Keyed on product ID, not image URL: the same product can carry a different
/// CDN URL between list and detail, which silently breaks the flight, and two
/// cards showing the same URL in one subtree throw "multiple heroes share the
/// same tag".
///
/// scope disambiguates a product appearing in more than one rail on the
/// same screen — a grid plus a "recommended" carousel is a normal marketplace
/// layout and is exactly where the duplicate-tag assert fires.
abstract final class WaveHeroTags {
  static String productImage(String productId, {String scope = 'main'}) =>
      'product_image_${scope}_$productId';
}
