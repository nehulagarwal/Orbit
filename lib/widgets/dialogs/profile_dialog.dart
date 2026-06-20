import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:flutter/material.dart';

import '../../screens/view_profile_screen.dart';

/// ProfileDialog — popup shown when tapping a user's profile picture.
/// Uses AlertDialog for simplicity with improved design.
class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      content: SizedBox(
        width: mq.width * .6,
        child: Column(
          mainAxisSize: MainAxisSize.min, // wrap content height
          children: [

            // ── Gradient header + avatar ───────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [

                // Gradient banner (same as ViewProfileScreen)
                Container(
                  height: mq.height * .1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),

                // Info button — top right corner
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () {
                      // Close dialog then open full profile
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewProfileScreen(user: user),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Avatar overlapping the gradient bottom edge
                Positioned(
                  bottom: -(mq.height * .055),
                  child: Container(
                    padding: const EdgeInsets.all(3), // white ring
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.image,
                        width: mq.height * .1,
                        height: mq.height * .1,
                        fit: BoxFit.cover,
                        // Spinner while loading
                        placeholder: (context, url) => Container(
                          color: Colors.blue.shade50,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        // Fallback icon on error
                        errorWidget: (context, url, error) => CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.person, color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Space to clear the overlapping avatar
            SizedBox(height: mq.height * .07),

            // ── User name ──────────────────────────────────────────────
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            // ── Online / Offline badge ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Coloured dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  user.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: user.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Divider for separation
            Divider(color: Colors.grey.shade200, thickness: 1),

            const SizedBox(height: 6),

            // ── About text ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                user.about.isNotEmpty ? user.about : '—',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),

            SizedBox(height: mq.height * .02),
          ],
        ),
      ),
    );
  }
}