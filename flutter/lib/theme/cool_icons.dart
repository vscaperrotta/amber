import 'package:flutter/widgets.dart';

/// Icon glyphs from the bundled Coolicons font (assets/fonts/coolicons.ttf),
/// replacing Material Icons app-wide. Coolicons ships with no name/codepoint
/// map, so each constant below was identified by rendering the full glyph
/// sheet and matching shapes by eye — see the codepoint comment.
///
/// A few Material icons have no Coolicons equivalent (no filled star, no
/// slash/"off" variant for search or filter): those map to the closest
/// single glyph, differentiated by color at the call site instead of shape.
abstract final class CoolIcons {
  static const _family = 'CoolIcons';

  static const homeOutline = IconData(0xE9EF, fontFamily: _family);

  static const starOutline = IconData(0xEA6F, fontFamily: _family);
  // Coolicons has no solid star — filled favorite reuses the outline glyph,
  // distinguished by amber color at the call site.
  static const starFilled = IconData(0xEA6F, fontFamily: _family);

  static const tagOutline = IconData(0xE9FB, fontFamily: _family);
  static const tagOff = IconData(0xE9FB, fontFamily: _family);

  static const search = IconData(0xEA52, fontFamily: _family);
  static const searchOff = IconData(0xEA52, fontFamily: _family);

  static const personOutline = IconData(0xEA95, fontFamily: _family);

  static const folder = IconData(0xE9D9, fontFamily: _family);
  static const save = IconData(0xEA51, fontFamily: _family);

  static const email = IconData(0xEA15, fontFamily: _family);
  static const emailRead = IconData(0xEA15, fontFamily: _family);

  static const deleteOutline = IconData(0xEA8A, fontFamily: _family);
  static const deleteFilled = IconData(0xEA8B, fontFamily: _family);

  static const add = IconData(0xE904, fontFamily: _family);

  static const eye = IconData(0xEA5F, fontFamily: _family);
  static const eyeOff = IconData(0xE9ED, fontFamily: _family);

  static const tune = IconData(0xEA68, fontFamily: _family);
  static const filterOff = IconData(0xEA68, fontFamily: _family);

  static const title = IconData(0xE9DB, fontFamily: _family);
  static const moreVert = IconData(0xEA2A, fontFamily: _family);
  static const logout = IconData(0xEA12, fontFamily: _family);
  static const lock = IconData(0xEA11, fontFamily: _family);

  static const linkOff = IconData(0xEA05, fontFamily: _family);
  static const link = IconData(0xEA06, fontFamily: _family);

  static const edit = IconData(0xE9B6, fontFamily: _family);
  static const download = IconData(0xE9AE, fontFamily: _family);
  static const close = IconData(0xE98D, fontFamily: _family);
  static const chevronRight = IconData(0xE981, fontFamily: _family);
  static const chevronLeft = IconData(0xE97F, fontFamily: _family);
}
