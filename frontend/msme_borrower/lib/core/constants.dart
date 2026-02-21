// App-wide constants: API base URL, colors, text styles
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── API ───────────────────────────────────────────────────────────────────
// For Android emulator: 10.0.2.2 maps to your localhost
// For real device on same WiFi: use your machine's local IP e.g. 192.168.x.x
const String kBaseUrl = 'http://10.0.2.2:8000';

// ── Colors ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFF7C5CBF); // Soft Lilac/Purple
const Color kPrimaryLight  = Color(0xFFB39DDB);
const Color kAccent        = Color(0xFFFFD18C); // Pastel Yellow
const Color kAccentPeach   = Color(0xFFFFB085); // Peach
const Color kBackground    = Color(0xFFF8F7FC); // Off-white
const Color kSurface       = Color(0xFFFFFFFF);
const Color kTextDark      = Color(0xFF2D2D3A); // Dark charcoal
const Color kTextMuted     = Color(0xFF8E8EA0);
const Color kSuccess       = Color(0xFF4CAF50);
const Color kError         = Color(0xFFE53935);
const Color kWarning       = Color(0xFFFF9800);

// ── Gradients ─────────────────────────────────────────────────────────────
const LinearGradient kHeroGradient = LinearGradient(
  colors: [Color(0xFF7C5CBF), Color(0xFF5B4A99)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFFFFD18C), Color(0xFFFFB085)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Typography ────────────────────────────────────────────────────────────
TextStyle kHeading1(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: kTextDark);

TextStyle kHeading2(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: kTextDark);

TextStyle kBody(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: kTextDark);

TextStyle kCaption(BuildContext context) =>
    GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: kTextMuted);

TextStyle kButtonText() =>
    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);

// ── Theme ─────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, surface: kBackground),
  scaffoldBackgroundColor: kBackground,
  textTheme: GoogleFonts.poppinsTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: kSurface,
    foregroundColor: kTextDark,
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w600, color: kTextDark,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
    labelStyle: GoogleFonts.poppins(color: kTextMuted),
  ),
);
