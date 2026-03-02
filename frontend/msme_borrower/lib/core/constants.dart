// App-wide constants: API base URL, colors, text styles
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── API ───────────────────────────────────────────────────────────────────
// Flutter Web → localhost | Android Emulator → 10.0.2.2
import 'package:flutter/foundation.dart' show kIsWeb;
String get kBaseUrl => kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

// ── Colors ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFF2A4B9B); // LendingKart Deep Navy Blue
const Color kPrimaryLight  = Color(0xFF4A6BCB);
const Color kAccent        = Color(0xFFFF7A00); // LendingKart Vibrant Orange
const Color kAccentTeal    = Color(0xFF00B0A8); // Complementary Teal
const Color kBackground    = Color(0xFFF4F7FA); // Soft off-white for contrast against white cards
const Color kSurface       = Color(0xFFFFFFFF); // Pure white cards
const Color kTextDark      = Color(0xFF1E293B); // Dark slate for primary text
const Color kTextMuted     = Color(0xFF64748B); // Cool grey for secondary text
const Color kSuccess       = Color(0xFF10B981); // Emerald Green
const Color kError         = Color(0xFFEF4444); // Red
const Color kWarning       = Color(0xFFF59E0B); // Amber

// ── Gradients ─────────────────────────────────────────────────────────────
const LinearGradient kHeroGradient = LinearGradient(
  colors: [Color(0xFF1E3A8A), Color(0xFF2A4B9B)], // Deep Blue to Navy
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)], // Subtle white card gradient
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Typography ────────────────────────────────────────────────────────────
TextStyle kHeading1(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: -0.5);

TextStyle kHeading2(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: kTextDark, letterSpacing: -0.3);

TextStyle kBody(BuildContext context) =>
    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: kTextDark);

TextStyle kCaption(BuildContext context) =>
    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: kTextMuted);

TextStyle kButtonText() =>
    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5);

// ── Theme ─────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, surface: kBackground, primary: kPrimary, secondary: kAccent),
  scaffoldBackgroundColor: kBackground,
  textTheme: GoogleFonts.interTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: kSurface,
    foregroundColor: kTextDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20, fontWeight: FontWeight.w600, color: kTextDark, letterSpacing: -0.2,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAccent, // LendingKart uses Orange for primary actions
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 4,
      shadowColor: kAccent.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Sharper corners
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
    labelStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 14),
    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
);
