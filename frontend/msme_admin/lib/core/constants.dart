import 'package:flutter/foundation.dart' show kIsWeb;

// ── API ───────────────────────────────────────────────────────────────────
String get kBaseUrl => kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

// ── Colors ────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

const Color kPrimary     = Color(0xFF7C5CBF); // Soft Lilac/Purple
const Color kAccent      = Color(0xFFFFC857); // Pastel Yellow
const Color kSuccess     = Color(0xFF4CAF50);
const Color kError       = Color(0xFFE53935);
const Color kWarning     = Color(0xFFFF9800);
const Color kBackground  = Color(0xFFF5F4FA);
const Color kSurface     = Color(0xFFFFFFFF);
const Color kSidebar     = Color(0xFF1E1B2E); // Dark navy for sidebar
const Color kSidebarText = Color(0xFFE0D9F5);
const Color kTextDark    = Color(0xFF2D2640);
const Color kTextMuted   = Color(0xFF9E97B0);

// ── Status Colors ─────────────────────────────────────────────────────────
const Map<String, Color> kStatusColors = {
  'DRAFT':        Color(0xFF9E9E9E),
  'PENDING':      Color(0xFF2196F3),
  'UNDER_REVIEW': Color(0xFFFF9800),
  'APPROVED':     Color(0xFF4CAF50),
  'REJECTED':     Color(0xFFE53935),
};

Color statusColor(String status) =>
    kStatusColors[status.toUpperCase()] ?? kTextMuted;
