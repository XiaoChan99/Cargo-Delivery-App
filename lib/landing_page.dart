import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/port_bg.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay for better readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC1565C0), Color(0xAA42A5F5), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          // Foreground content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Hero Illustration
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      height: 120,
                      child: SvgPicture.string(
                        _portSvg,
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  // Headline
                  Text(
                    "Streamline Port Congestion Management",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tagline
                  Text(
                    "Deliveries. Insights. Efficiency.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.blueAccent[700],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Subheadline
                  Text(
                    "Real-time congestion insights, faster deliveries, and smarter scheduling for modern ports.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Card with buttons
                  Card(
                    elevation: 10,
                    color: Colors.white.withOpacity(0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Login with Google Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: SvgPicture.string(_googleSvg, height: 22),
                              label: const Text(
                                "Login with Google",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.black12),
                                ),
                                shadowColor: Colors.blueAccent.withOpacity(0.15),
                              ),
                              onPressed: () {
                                // TODO: Implement Google OAuth
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Footer
                  Text(
                    "© 2025 Cargo Port Solutions",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ...existing SVG constants...
const String _portSvg = '''
<svg width="120" height="120" viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="70" width="84" height="18" rx="6" fill="#E3F2FD"/>
  <rect x="30" y="60" width="60" height="18" rx="6" fill="#90CAF9"/>
  <rect x="42" y="50" width="36" height="18" rx="6" fill="#1976D2"/>
  <rect x="54" y="40" width="12" height="18" rx="6" fill="#1565C0"/>
  <rect x="10" y="88" width="100" height="8" rx="4" fill="#B0BEC5"/>
  <rect x="20" y="96" width="80" height="8" rx="4" fill="#78909C"/>
  <circle cx="30" cy="104" r="4" fill="#1976D2"/>
  <circle cx="90" cy="104" r="4" fill="#1976D2"/>
</svg>
''';

const String _googleSvg = '''
<svg width="22" height="22" viewBox="0 0 22 22">
  <g>
    <path fill="#4285F4" d="M21.6 11.227c0-.747-.067-1.467-.192-2.16H11v4.09h5.97a5.11 5.11 0 0 1-2.22 3.36v2.79h3.6c2.1-1.94 3.29-4.8 3.29-8.08z"/>
    <path fill="#34A853" d="M11 22c2.97 0 5.46-.98 7.28-2.66l-3.6-2.79c-1 .67-2.28 1.07-3.68 1.07-2.83 0-5.23-1.91-6.08-4.48H1.22v2.82A10.99 10.99 0 0 0 11 22z"/>
    <path fill="#FBBC05" d="M4.92 13.14A6.6 6.6 0 0 1 4.4 11c0-.74.13-1.46.32-2.14V6.04H1.22A10.99 10.99 0 0 0 0 11c0 1.74.42 3.39 1.22 4.96l3.7-2.82z"/>
    <path fill="#EA4335" d="M11 4.36c1.62 0 3.07.56 4.22 1.66l3.16-3.16C16.46 1.01 13.97 0 11 0A10.99 10.99 0 0 0 1.22 6.04l3.7 2.82C5.77 6.27 8.17 4.36 11 4.36z"/>
  </g>
</svg>
''';