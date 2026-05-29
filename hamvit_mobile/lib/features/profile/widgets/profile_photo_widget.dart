import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_photo_service.dart';

class ProfilePhotoWidget extends ConsumerStatefulWidget {
  final String? photoUrl;
  final String? displayName;
  final double size;
  final bool editable;
  final VoidCallback? onTap;

  const ProfilePhotoWidget({
    super.key,
    this.photoUrl,
    this.displayName,
    this.size = 100,
    this.editable = false,
    this.onTap,
  });

  @override
  ConsumerState<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends ConsumerState<ProfilePhotoWidget> {
  String? _initial;

  @override
  void initState() {
    super.initState();
    _initial = _getInitial();
  }

  @override
  void didUpdateWidget(ProfilePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayName != widget.displayName) {
      _initial = _getInitial();
    }
  }

  String? _getInitial() {
    if (widget.displayName == null || widget.displayName!.trim().isEmpty) return null;
    return widget.displayName!.trim()[0].toUpperCase();
  }

  // The photo options UI is shown by the parent screen. When tapped,
  // delegate the action to the parent via `widget.onTap` to avoid
  // opening duplicate bottom sheets.

  Widget _optionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 24),
      title: Text(
        label,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: widget.editable ? widget.onTap : null,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                      fadeInDuration: const Duration(milliseconds: 300),
                    )
                  : _placeholder(),
            ),
          ),
          if (widget.editable)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00B4D8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          if (widget.editable && !hasPhoto)
            Positioned(
              bottom: -6,
              child: SizedBox(
                width: widget.size,
                child: const Text(
                  'Alterar foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00B4D8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    if (_initial != null) {
      return Container(
        color: const Color(0xFF1B2838),
        alignment: Alignment.center,
        child: Text(
          _initial!,
          style: TextStyle(
            color: const Color(0xFF00B4D8),
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF1B2838),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        color: Colors.white38,
        size: widget.size * 0.45,
      ),
    );
  }
}