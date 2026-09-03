/// Liquid Glass design system (inspired by iOS 26 / ColorOS 17).
///
/// Provides an animated ambient background, frosted-glass surfaces with
/// specular highlights, springy press feedback and a floating glass nav bar.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassColors {
  GlassColors._();

  // Vibrant "liquid" palette that bleeds through frosted surfaces.
  static const primary = Color(0xFF6C63FF);
  static const cyan = Color(0xFF2AE6FF);
  static const teal = Color(0xFF00E5B0);
  static const magenta = Color(0xFFFF4FB0);
  static const violet = Color(0xFF9D4EFF);
  static const amber = Color(0xFFFFB020);
  static const rose = Color(0xFFFF6B6B);

  // Surface tints (semi-transparent so the ambient background shows through).
  static const glassTint = Color(0x14FFFFFF); // ~8% white
  static const glassTintStrong = Color(0x24FFFFFF); // ~14% white
  static const glassStroke = Color(0x33FFFFFF); // ~20% white
  static const glassStrokeTop = Color(0x59FFFFFF); // ~35% white highlight
}

/// A gentle, slowly-drifting ambient background made of blurred gradient
/// orbs. Sits behind the whole app so frosted surfaces have something to blur.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final bool dark;
  const AmbientBackground({super.key, required this.child, this.dark = true});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final base = widget.dark
        ? const Color(0xFF080816)
        : const Color(0xFFEEF0FF);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base wash
        Container(color: base),

        // Drifting orbs
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              children: [
                _Orb(
                  size: size.width * 1.15,
                  x: size.width * (0.5 + 0.42 * math.sin(t * 2 * math.pi)),
                  y: size.height * (0.12 + 0.18 * math.sin(t * 2 * math.pi + 1.3)),
                  colors: const [GlassColors.primary, GlassColors.violet],
                ),
                _Orb(
                  size: size.width * 1.0,
                  x: size.width * (0.85 + 0.30 * math.sin(t * 2 * math.pi + 2.1)),
                  y: size.height * (0.55 + 0.22 * math.sin(t * 2 * math.pi + 0.6)),
                  colors: const [GlassColors.cyan, GlassColors.teal],
                ),
                _Orb(
                  size: size.width * 1.2,
                  x: size.width * (0.2 + 0.35 * math.sin(t * 2 * math.pi + 4.2)),
                  y: size.height * (0.85 + 0.15 * math.sin(t * 2 * math.pi + 2.8)),
                  colors: const [GlassColors.magenta, GlassColors.rose],
                ),
                _Orb(
                  size: size.width * 0.9,
                  x: size.width * (0.6 + 0.4 * math.sin(t * 2 * math.pi + 5.0)),
                  y: size.height * (0.3 + 0.25 * math.sin(t * 2 * math.pi + 3.5)),
                  colors: const [GlassColors.amber, GlassColors.rose],
                ),
              ],
            );
          },
        ),

        // Subtle grain / vignette for depth
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.12),
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),

        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final double x;
  final double y;
  final List<Color> colors;
  const _Orb({
    required this.size,
    required this.x,
    required this.y,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors[0].withOpacity(0.55),
              colors[1].withOpacity(0.28),
              colors[1].withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass panel: blurs whatever is behind it and adds a translucent
/// fill plus a specular top-edge highlight.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color tint;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.blur = 22,
    this.tint = GlassColors.glassTint,
    this.borderColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint, tint.withValues(alpha: tint.a * 0.55)],
                ),
            border: Border.all(
              color: borderColor ?? GlassColors.glassStroke,
              width: 1,
            ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
          ),
          child: Stack(
            children: [
              // Specular highlight along the top edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        GlassColors.glassStrokeTop,
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable frosted card with springy press-down feedback and a soft glow.
class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;
  final List<Color>? accent; // optional liquid gradient wash
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.glowColor,
    this.accent,
    this.gradient,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onTap == null) return;
    _pressed = true;
    _scale.animateTo(0.965, curve: Curves.easeOut).then((_) {});
  }

  void _onTapUp(_) {
    if (!_pressed) return;
    _pressed = false;
    _scale.animateTo(1, curve: Curves.easeOutBack);
  }

  void _onTapCancel() {
    if (!_pressed) return;
    _pressed = false;
    _scale.animateTo(1, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final glow = widget.glowColor;

    Widget surface = GlassSurface(
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      gradient: widget.gradient,
      boxShadow: glow != null
          ? [
              BoxShadow(
                color: glow.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: glow.withOpacity(0.18),
                blurRadius: 60,
                offset: const Offset(0, 24),
              ),
            ]
          : null,
      child: widget.child,
    );

    if (widget.accent != null) {
      surface = ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.accent!,
                  ),
                ),
              ),
            ),
            surface,
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: surface,
      ),
    );
  }
}

/// Wraps any widget with a springy press-down scale for tactile feedback.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap == null) return;
    _pressed = true;
    _c.animateTo(widget.pressedScale, curve: Curves.easeOut);
  }

  void _up() {
    if (!_pressed) return;
    _pressed = false;
    _c.animateTo(1, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _c,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        child: widget.child,
      ),
    );
  }
}

/// A floating, pill-shaped glass bottom navigation bar.
class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<({IconData icon, IconData selectedIcon, String label})> destinations;
  final Color activeColor;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.activeColor = GlassColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 30,
        blur: 28,
        tint: const Color(0x2E14142E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                icon: destinations[i].icon,
                selectedIcon: destinations[i].selectedIcon,
                label: destinations[i].label,
                selected: i == selectedIndex,
                activeColor: activeColor,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? activeColor.withOpacity(0.28) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 23,
              color: selected ? activeColor : Colors.white54,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A frosted-glass top app bar that blurs content scrolling beneath it.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final Widget? leading;
  const GlassAppBar({
    super.key,
    this.title = '',
    this.actions = const [],
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A1E).withOpacity(0.9),
            const Color(0xFF0A0A1E).withOpacity(0.55),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: GlassColors.glassStroke, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 4)],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              ...actions,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A liquid gradient action button with spring press feedback.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> gradient;
  final bool expanded;
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = const [GlassColors.primary, GlassColors.violet],
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return TapScale(
      onTap: onPressed,
      child: SizedBox(width: expanded ? double.infinity : null, child: button),
    );
  }
}
