import 'package:material_ui/material_ui.dart';

/// Palette tokens — the single source of truth for every colour in the app.
///
/// These values are the cinematic dark-Arthurian palette adopted for the design
/// system refresh (see `DESIGN_SYSTEM.md`). Nothing outside this file may hold
/// a raw colour value.
abstract final class AppColors {
  /// Primary background: near-black midnight.
  static const background = Color(0xFF0B0E14);

  /// Secondary background: raised areas behind cards and panels.
  static const backgroundSecondary = Color(0xFF121A28);

  /// Panels, cards and input surfaces.
  static const surface = Color(0xFF202B3B);

  /// A panel that needs to sit above another panel.
  static const surfaceRaised = Color(0xFF2A3749);

  /// Primary gold accent: actions, selected state, ornaments.
  static const gold = Color(0xFFC5A15B);

  /// Light gold: highlights on gold surfaces and quiet accents.
  static const lightGold = Color(0xFFE2C98D);

  /// Muted gold: supporting ornament that must not compete with [gold].
  static const mutedGold = Color(0xFF8E7440);

  /// Primary text.
  static const parchment = Color(0xFFF1F0EB);

  /// Secondary text: supporting sentences and labels.
  static const textSecondary = Color(0xFFBBC3CE);

  /// Muted text: captions, hints and disabled labels.
  static const mutedText = Color(0xFF8492A6);

  /// Neutral: dividers of lesser weight, inactive indicators.
  static const neutral = Color(0xFF8492A6);

  static const success = Color(0xFF3D9B72);
  static const danger = Color(0xFFB84B4B);
  static const divider = Color(0xFF2C3748);

  /// Deep red at the foot of a destructive button, so it reads as a surface
  /// rather than a flat block.
  static const dangerDeep = Color(0xFF8F3636);

  /// Hairline drawn on the top edge of a raised surface: a button, a card rim.
  static const hairline = Color(0x38F1F0EB);

  /// The same hairline at zero alpha, so a shine can fade out at both ends.
  static const hairlineFade = Color(0x00F1F0EB);

  /// The glow under a gold action, and under a destructive one.
  static const goldGlow = Color(0x40C5A15B);
  static const dangerGlow = Color(0x40B84B4B);

  /// Text/icon colour appropriate on top of gold surfaces.
  static const onGold = Color(0xFF0B0E14);

  /// Gold at 13% opacity — the single overlay used for press ripples, slider
  /// halos and other passive gold glows.
  static const goldOverlay = Color(0x22C5A15B);

  /// Legibility veil laid over cinematic artwork, top to bottom. The artwork
  /// stays visible near the top and fades into the background behind content.
  static const veilTop = Color(0x8C0B0E14);
  static const veilMiddle = Color(0xCC0B0E14);
  static const veilBottom = Color(0xF70B0E14);
}
