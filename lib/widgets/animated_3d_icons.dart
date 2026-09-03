import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Common 3D Base Pod / Pedestal Painter with radial glow and depth shadow
class _Podium3DPainter extends CustomPainter {
  final Color primaryColor;
  final double animationProgress;

  _Podium3DPainter({
    required this.primaryColor,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radiusX = size.width * 0.44;
    final radiusY = size.height * 0.18;

    // 1. Ambient Glow Ring
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withAlpha((70 + 20 * math.sin(animationProgress * 2 * math.pi)).toInt()),
          primaryColor.withAlpha(0),
        ],
      ).createShader(Rect.fromCenter(center: center, width: radiusX * 2.8, height: radiusY * 3.2));
    canvas.drawOval(Rect.fromCenter(center: center, width: radiusX * 2.8, height: radiusY * 3.2), glowPaint);

    // 2. Base Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 6 + 2 * math.sin(animationProgress * 2 * math.pi)),
        width: radiusX * 2.0,
        height: radiusY * 1.8,
      ),
      shadowPaint,
    );

    // 3. 3D Beveled Base Cylinder (Front Face / Depth)
    final depthRect = Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);
    final baseDepthPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withAlpha(140),
          primaryColor.withAlpha(220),
        ],
      ).createShader(depthRect);

    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: radiusX * 2, height: radiusY * 2));
    canvas.drawPath(path, baseDepthPaint);

    // 4. Top Ellipse Platform Face
    final topRect = Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(240),
          primaryColor.withAlpha(40),
          primaryColor.withAlpha(120),
        ],
      ).createShader(topRect);
    canvas.drawOval(topRect, topPaint);

    // 5. Highlight Rim
    final rimPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawOval(topRect, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _Podium3DPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}

// ============================================================================
// 1. 3D ANIMATED KIRANA MERCHANT ICON
// ============================================================================
class Animated3DMerchantIcon extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const Animated3DMerchantIcon({
    super.key,
    this.size = 84.0,
    this.onTap,
  });

  @override
  State<Animated3DMerchantIcon> createState() => _Animated3DMerchantIconState();
}

class _Animated3DMerchantIconState extends State<Animated3DMerchantIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B5E20); // Emerald Kirana Green
    const accent = Color(0xFF4CAF50);
    const gold = Color(0xFFFFB300);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final floatOffset = math.sin(t * 2 * math.pi) * 5.0;
          final tiltAngle = math.sin(t * 2 * math.pi) * 0.04;
          final shimmerT = (t * 2) % 1.0;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. 3D Glowing Podium Base
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _Podium3DPainter(
                    primaryColor: primary,
                    animationProgress: t,
                  ),
                ),

                // 2. Floating 3D Kirana Shop Body with Perspective Tilt
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // 3D perspective depth
                    ..setTranslationRaw(0.0, -8.0 + floatOffset, 0.0)
                    ..rotateX(0.06 + tiltAngle * 0.5)
                    ..rotateY(-0.10 + tiltAngle),
                  child: Container(
                    width: widget.size * 0.72,
                    height: widget.size * 0.68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF1B5E20),
                          Color(0xFF0A3610),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D2818).withAlpha(120),
                          blurRadius: 12,
                          offset: const Offset(4, 8),
                        ),
                        BoxShadow(
                          color: accent.withAlpha(90),
                          blurRadius: 18,
                          offset: const Offset(-2, -4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha(140),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 3D Striped Awning at Top
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: widget.size * 0.22,
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                              gradient: LinearGradient(
                                colors: [Color(0xFFE8F5E9), Color(0xFF81C784)],
                              ),
                            ),
                            child: Row(
                              children: List.generate(5, (index) {
                                final isDark = index % 2 == 1;
                                return Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? primary : Colors.white,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // Storefront Display Center Icon
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: widget.size * 0.14),
                            child: Icon(
                              Icons.storefront_rounded,
                              size: widget.size * 0.36,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Diagonal Light Reflection Sweep
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Transform.translate(
                              offset: Offset(widget.size * (shimmerT * 2.5 - 1.0), 0),
                              child: Transform.rotate(
                                angle: 0.4,
                                child: Container(
                                  width: widget.size * 0.2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.white.withAlpha(70),
                                        Colors.white.withAlpha(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Floating 3D Shopping Basket / Cart Accessory
                Positioned(
                  right: widget.size * 0.04,
                  bottom: widget.size * 0.18 + floatOffset * 0.7,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateZ(0.12)
                      ..rotateY(-0.15),
                    child: Container(
                      padding: EdgeInsets.all(widget.size * 0.07),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [gold, Color(0xFFFF8F00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withAlpha(160),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        size: widget.size * 0.20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 4. Floating Sparkle Stars
                Positioned(
                  left: widget.size * 0.06,
                  top: widget.size * 0.10 + math.cos(t * 2 * math.pi) * 3,
                  child: Icon(
                    Icons.auto_awesome,
                    size: widget.size * 0.16,
                    color: gold.withAlpha(220),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  }
}

// ============================================================================
// 2. 3D ANIMATED FIELD SALESMAN ICON
// ============================================================================
class Animated3DSalesmanIcon extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const Animated3DSalesmanIcon({
    super.key,
    this.size = 84.0,
    this.onTap,
  });

  @override
  State<Animated3DSalesmanIcon> createState() => _Animated3DSalesmanIconState();
}

class _Animated3DSalesmanIconState extends State<Animated3DSalesmanIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE65100); // Field Sales Amber/Orange
    const accent = Color(0xFFFF9800);
    const highlight = Color(0xFFFFD54F);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final floatOffset = math.sin(t * 2 * math.pi) * 5.5;
          final tiltAngle = math.cos(t * 2 * math.pi) * 0.05;
          final chartPulse1 = (math.sin(t * 2 * math.pi) + 1) / 2;
          final chartPulse2 = (math.cos(t * 2 * math.pi) + 1) / 2;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. 3D Glowing Amber Podium Base
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _Podium3DPainter(
                    primaryColor: primary,
                    animationProgress: t,
                  ),
                ),

                // 2. Floating 3D Executive Briefcase / Tablet in Perspective
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..setTranslationRaw(0.0, -8.0 + floatOffset, 0.0)
                    ..rotateX(0.08 + tiltAngle)
                    ..rotateY(0.12 - tiltAngle * 0.6),
                  child: Container(
                    width: widget.size * 0.72,
                    height: widget.size * 0.66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6D00),
                          Color(0xFFE65100),
                          Color(0xFFBF360C),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFBF360C).withAlpha(140),
                          blurRadius: 14,
                          offset: const Offset(4, 8),
                        ),
                        BoxShadow(
                          color: accent.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(-2, -3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha(150),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Briefcase / Tablet Handle at Top
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: widget.size * 0.28,
                            height: widget.size * 0.08,
                            decoration: const BoxDecoration(
                              color: highlight,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Content: Dynamic Rising Order Bar Graph
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: widget.size * 0.12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Bar 1
                                Container(
                                  width: widget.size * 0.08,
                                  height: widget.size * (0.16 + 0.10 * chartPulse1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(180),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                SizedBox(width: widget.size * 0.04),
                                // Bar 2
                                Container(
                                  width: widget.size * 0.08,
                                  height: widget.size * (0.24 + 0.12 * chartPulse2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(220),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                SizedBox(width: widget.size * 0.04),
                                // Bar 3 (Highest)
                                Container(
                                  width: widget.size * 0.08,
                                  height: widget.size * (0.34 + 0.08 * chartPulse1),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [highlight, Colors.white],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Badge / Verified Handshake icon overlay
                        Positioned(
                          top: widget.size * 0.10,
                          right: widget.size * 0.06,
                          child: Icon(
                            Icons.verified_rounded,
                            size: widget.size * 0.18,
                            color: highlight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Floating 3D Growth Trend Arrow Badge
                Positioned(
                  right: widget.size * 0.02,
                  top: widget.size * 0.08 - floatOffset * 0.5,
                  child: Container(
                    padding: EdgeInsets.all(widget.size * 0.06),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withAlpha(150),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      size: widget.size * 0.20,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 4. Floating 3D Rupee / Commission Coin
                Positioned(
                  left: widget.size * 0.04,
                  bottom: widget.size * 0.16 + floatOffset * 0.6,
                  child: Container(
                    width: widget.size * 0.22,
                    height: widget.size * 0.22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [highlight, Color(0xFFFF8F00)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Center(
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: widget.size * 0.13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  }
}

// ============================================================================
// 3. 3D ANIMATED DELIVERY PARTNER ICON
// ============================================================================
class Animated3DDeliveryIcon extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const Animated3DDeliveryIcon({
    super.key,
    this.size = 84.0,
    this.onTap,
  });

  @override
  State<Animated3DDeliveryIcon> createState() => _Animated3DDeliveryIconState();
}

class _Animated3DDeliveryIconState extends State<Animated3DDeliveryIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4A148C); // Royal Delivery Violet
    const accent = Color(0xFF7C4DFF);
    const cyan = Color(0xFF00E5FF);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          // Road vibration + floating bounce
          final floatOffset = math.sin(t * 2 * math.pi) * 4.5;
          final wheelRotation = t * 2 * math.pi;
          final roadStreak = (t * 2) % 1.0;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. 3D Glowing Purple-Cyan Podium Base
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _Podium3DPainter(
                    primaryColor: primary,
                    animationProgress: t,
                  ),
                ),

                // 2. Animated Speed Wind Trails (behind truck)
                Positioned(
                  left: widget.size * 0.02,
                  top: widget.size * 0.35 + floatOffset * 0.3,
                  child: Opacity(
                    opacity: (1.0 - roadStreak).clamp(0.0, 1.0),
                    child: Row(
                      children: [
                        Container(
                          width: widget.size * 0.16 * (1.0 - roadStreak * 0.5),
                          height: 3,
                          decoration: BoxDecoration(
                            color: cyan.withAlpha(180),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          width: widget.size * 0.08,
                          height: 3,
                          decoration: BoxDecoration(
                            color: cyan.withAlpha(140),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Floating 3D Express Delivery Van / Truck
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..setTranslationRaw(0.0, -8.0 + floatOffset, 0.0)
                    ..rotateX(0.08)
                    ..rotateY(-0.14)
                    ..rotateZ(math.sin(t * 4 * math.pi) * 0.015), // suspension wobble
                  child: Container(
                    width: widget.size * 0.74,
                    height: widget.size * 0.64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7B1FA2),
                          Color(0xFF4A148C),
                          Color(0xFF311B92),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF311B92).withAlpha(140),
                          blurRadius: 14,
                          offset: const Offset(4, 8),
                        ),
                        BoxShadow(
                          color: accent.withAlpha(110),
                          blurRadius: 16,
                          offset: const Offset(-2, -3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha(150),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Truck Delivery Graphic / Icon
                        Center(
                          child: Icon(
                            Icons.local_shipping_rounded,
                            size: widget.size * 0.42,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        // Animated Rotating Wheels at Bottom of Truck
                        Positioned(
                          bottom: widget.size * 0.08,
                          left: widget.size * 0.12,
                          child: Transform.rotate(
                            angle: wheelRotation,
                            child: Container(
                              width: widget.size * 0.12,
                              height: widget.size * 0.12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF212121),
                                border: Border.all(color: cyan, width: 1.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: widget.size * 0.08,
                          right: widget.size * 0.14,
                          child: Transform.rotate(
                            angle: wheelRotation,
                            child: Container(
                              width: widget.size * 0.12,
                              height: widget.size * 0.12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF212121),
                                border: Border.all(color: cyan, width: 1.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Express Badge
                        Positioned(
                          top: widget.size * 0.08,
                          right: widget.size * 0.08,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: cyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'EXPRESS',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF004D40),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Floating 3D GPS Location Pin with Pulse
                Positioned(
                  right: widget.size * 0.04,
                  top: widget.size * 0.06 + floatOffset * 0.7,
                  child: Container(
                    padding: EdgeInsets.all(widget.size * 0.05),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withAlpha(160),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Icon(
                      Icons.near_me_rounded,
                      size: widget.size * 0.18,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 5. Floating Box Package Parcel
                Positioned(
                  left: widget.size * 0.06,
                  bottom: widget.size * 0.18 - floatOffset * 0.5,
                  child: Container(
                    padding: EdgeInsets.all(widget.size * 0.05),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: widget.size * 0.16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  }
}
