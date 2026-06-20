import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../helper/my_date_util.dart';
import '../../main.dart';
import '../../models/chat_user.dart';

/// ViewProfileScreen — displays a read-only profile card for a [ChatUser].
/// Navigated to when the user taps the profile header in ChatScreen.
class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen>
    with SingleTickerProviderStateMixin {

  // Animation controller for the entrance fade+slide effect
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Set up a short entrance animation (400ms)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08), // slides up slightly
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // Start animation as soon as screen mounts
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent app bar so the header image bleeds into it
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Back button with a frosted-glass look
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // ── Top hero section with gradient background ──────────────────
              _buildHeroSection(),

              // ── Info cards below ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: mq.width * .05,
                    vertical: mq.height * .02,
                  ),
                  child: Column(
                    children: [
                      // Email card
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: widget.user.email,
                      ),

                      SizedBox(height: mq.height * .015),

                      // About card
                      _buildInfoCard(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        value: widget.user.about,
                      ),

                      SizedBox(height: mq.height * .015),

                      // Joined date card
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined On',
                        value: MyDateUtil.getLastMessageTime(
                          context: context,
                          time: widget.user.createdAt,
                          showYear: true,
                        ),
                      ),

                      SizedBox(height: mq.height * .03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top hero section:
  /// gradient background + circular avatar + name + online badge
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: mq.height * .12, // clears the app bar
        bottom: mq.height * .04,
      ),
      decoration: const BoxDecoration(
        // Soft blue-to-indigo gradient matching the app's chat screen color
        gradient: LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // ── Profile picture with white ring border ─────────────────────
          Container(
            padding: const EdgeInsets.all(4), // white ring
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.user.image,
                width: mq.height * .15,
                height: mq.height * .15,
                fit: BoxFit.cover,
                // Show a shimmer-style placeholder while loading
                placeholder: (context, url) => Container(
                  color: Colors.white24,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                // Fallback avatar icon on error
                errorWidget: (context, url, error) => const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),

          SizedBox(height: mq.height * .015),

          // ── User name ──────────────────────────────────────────────────
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          // ── Online / Offline badge ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Green dot for online, grey for offline
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.user.isOnline
                      ? Colors.greenAccent
                      : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.user.isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Reusable info card widget.
  /// Shows an [icon], a [label] (e.g. "Email"), and the actual [value].
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon in a soft blue circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),

          const SizedBox(width: 14),

          // Label + value stacked vertically
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small muted label
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                // Actual value
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}