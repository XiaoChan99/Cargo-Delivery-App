import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.indigo[900]!,
              Colors.blue[900]!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle geometric pattern
            Opacity(
              opacity: 0.03,
              child: SvgPicture.string(
                _geometricPatternSvg,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Background elements
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            SafeArea(
              minimum: EdgeInsets.all(isSmallScreen ? 20 : 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // App logo and name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          _appLogoSvg,
                          width: 52,
                          height: 52,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "PORTFLOW",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.5,
                            fontSize: isSmallScreen ? 22 : 28,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Hero illustration
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SvgPicture.string(
                        _modernPortSvg,
                        width: isSmallScreen ? screenWidth * 0.8 : 450,
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Headline
                    Text(
                      "Optimize Port Operations\nwith Real-Time Intelligence",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                        fontSize: isSmallScreen ? 30 : 40,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tagline
                    Text(
                      "REDUCE CONGESTION • ACCELERATE DELIVERIES • ENHANCE EFFICIENCY",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.blue[100],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Benefits section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBenefitItem("Real-time Tracking", Icons.track_changes_rounded),
                          _buildBenefitItem("Smart Scheduling", Icons.schedule_rounded),
                          _buildBenefitItem("Data Analytics", Icons.analytics_rounded),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Action card
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Get Started",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue[900],
                                  fontSize: 24,
                                ),
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // Google Sign In button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Implement Google OAuth
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.grey[800],
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    shadowColor: Colors.black.withOpacity(0.1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.string(
                                        _googleSvg,
                                        height: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Continue with Google",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      "or",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Email login button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadowColor: Colors.blue[800]!.withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    "Sign in with Email",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(color: Colors.grey[600]),
                                    children: [
                                      TextSpan(
                                        text: "Sign up",
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Footer
                    Text(
                      "© 2025 PortFlow • Maritime Efficiency Solutions",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem(String text, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue[700]!.withOpacity(0.3),
                Colors.blue[500]!.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// SVG constants remain the same as in your original code
const String _modernPortSvg = '''
<svg viewBox="0 0 500 300" xmlns="http://www.w3.org/2000/svg">
  <!-- Water with more realistic waves -->
  <defs>
    <linearGradient id="waterDeep" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#0d47a1" />
      <stop offset="100%" stop-color="#1565c0" />
    </linearGradient>
    <linearGradient id="waterMid" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#1976d2" />
      <stop offset="100%" stop-color="#1e88e5" />
    </linearGradient>
    <linearGradient id="waterLight" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#42a5f5" />
      <stop offset="100%" stop-color="#64b5f6" />
    </linearGradient>
  </defs>
  
  <!-- Deep water -->
  <rect x="0" y="220" width="500" height="80" fill="url(#waterDeep)" />
  
  <!-- Wave patterns -->
  <path d="M0,230 Q100,220 200,230 T400,225 T500,230 L500,240 L0,240 Z" fill="url(#waterMid)" opacity="0.8" />
  <path d="M0,240 Q150,235 250,240 T500,235 L500,250 L0,250 Z" fill="url(#waterLight)" opacity="0.6" />
  
  <!-- Pier with more detail -->
  <rect x="100" y="180" width="300" height="40" fill="#5d4037" />
  <rect x="120" y="160" width="260" height="20" fill="#6d4c41" />
  <line x1="120" y1="160" x2="120" y2="180" stroke="#4e342e" stroke-width="2" />
  <line x1="380" y1="160" x2="380" y2="180" stroke="#4e342e" stroke-width="2" />
  <line x1="200" y1="160" x2="200" y2="180" stroke="#4e342e" stroke-width="1" opacity="0.7" />
  <line x1="280" y1="160" x2="280" y2="180" stroke="#4e342e" stroke-width="1" opacity="0.7" />
  
  <!-- Cranes with more detail -->
  <g stroke="#455a64" stroke-width="3">
    <!-- Left Crane -->
    <rect x="140" y="120" width="8" height="60" fill="#78909c" />
    <rect x="125" y="120" width="38" height="10" fill="#b0bec5" rx="2" />
    <path d="M144,120 L144,80 L160,80 L160,100 L144,100 Z" fill="#607d8b" />
    <line x1="144" y1="100" x2="160" y2="100" stroke-width="2" />
    <circle cx="152" cy="90" r="2" fill="#37474f" />
    
    <!-- Middle Crane -->
    <rect x="240" y="100" width="8" height="80" fill="#78909c" />
    <rect x="225" y="100" width="38" height="10" fill="#b0bec5" rx="2" />
    <path d="M244,100 L244,60 L260,60 L260,80 L244,80 Z" fill="#607d8b" />
    <line x1="244" y1="80" x2="260" y2="80" stroke-width="2" />
    <circle cx="252" cy="70" r="2" fill="#37474f" />
    
    <!-- Right Crane -->
    <rect x="340" y="140" width="8" height="40" fill="#78909c" />
    <rect x="325" y="140" width="38" height="10" fill="#b0bec5" rx="2" />
    <path d="M344,140 L344,120 L360,120 L360,140 L344,140 Z" fill="#607d8b" />
    <line x1="344" y1="120" x2="360" y2="120" stroke-width="2" />
  </g>
  
  <!-- Containers with more realistic look -->
  <g stroke="#263238" stroke-width="0.5">
    <rect x="160" y="140" width="40" height="20" fill="#e53935" rx="1" />
    <rect x="160" y="120" width="40" height="20" fill="#1e88e5" rx="1" />
    <line x1="160" y1="130" x2="200" y2="130" stroke="white" stroke-width="0.5" opacity="0.3" />
    
    <rect x="200" y="140" width="40" height="20" fill="#43a047" rx="1" />
    <line x1="200" y1="150" x2="240" y2="150" stroke="white" stroke-width="0.5" opacity="0.3" />
    
    <rect x="260" y="120" width="40" height="20" fill="#fdd835" rx="1" />
    <line x1="260" y1="130" x2="300" y2="130" stroke="white" stroke-width="0.5" opacity="0.3" />
    
    <rect x="300" y="140" width="40" height="20" fill="#7b1fa2" rx="1" />
    <rect x="300" y="120" width="40" height="20" fill="#e53935" rx="1" />
    <line x1="300" y1="130" x2="340" y2="130" stroke="white" stroke-width="0.5" opacity="0.3" />
  </g>
  
  <!-- Ship with more detail -->
  <defs>
    <linearGradient id="shipBody" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#546e7a" />
      <stop offset="100%" stop-color="#37474f" />
    </linearGradient>
  </defs>
  
  <path d="M50,200 L120,200 Q140,190 160,200 L200,200 Q220,185 240,200 L280,200 Q300,190 320,200 L350,200 L360,220 L40,220 Z" fill="url(#shipBody)" />
  <rect x="80" y="170" width="40" height="30" fill="#78909c" rx="1" />
  <rect x="180" y="170" width="30" height="30" fill="#90a4ae" rx="1" />
  <rect x="280" y="170" width="40" height="30" fill="#78909c" rx="1" />
  
  <!-- Windows on ship -->
  <circle cx="90" cy="180" r="2" fill="#e3f2fd" />
  <circle cx="100" cy="180" r="2" fill="#e3f2fd" />
  <circle cx="190" cy="180" r="2" fill="#e3f2fd" />
  <circle cx="200" cy="180" r="2" fill="#e3f2fd" />
  <circle cx="290" cy="180" r="2" fill="#e3f2fd" />
  <circle cx="300" cy="180" r="2" fill="#e3f2fd" />
  
  <!-- Reflection on water -->
  <path d="M80,220 L100,218 L150,219 L200,218 L250,219 L300,218 L350,219 L380,220" 
        stroke="white" stroke-width="0.5" opacity="0.2" fill="none" />
</svg>
''';

const String _appLogoSvg = '''
<svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="24" fill="url(#logoGradient)"/>
  <defs>
    <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1565C0" />
      <stop offset="100%" stop-color="#0D47A1" />
    </linearGradient>
  </defs>
  <path d="M30 30V18H22V30H30Z" fill="white"/>
  <path d="M20 30V20H16V30H20Z" fill="white"/>
  <path d="M12 30L12 24H34V30H12Z" fill="white"/>
</svg>
''';

const String _geometricPatternSvg = '''
<svg width="100%" height="100%" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <pattern id="hexagons" width="10" height="8.66" patternUnits="userSpaceOnUse" patternTransform="rotate(30)">
      <path d="M0,0 L5,0 L10,0 L10,4.33 L5,8.66 L0,4.33 Z" fill="none" stroke="white" stroke-width="0.3" opacity="0.2"/>
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#hexagons)" />
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