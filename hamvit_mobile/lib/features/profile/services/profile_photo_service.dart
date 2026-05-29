import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePhotoService {
  final SupabaseClient _supabase;
  static const _bucket = 'profile-photos';
  static const _maxSizeBytes = 5 * 1024 * 1024; // 5MB
  static const _maxDimension = 1024;
  static const _quality = 85;

  ProfilePhotoService(this._supabase);

  String _storagePath(String userId) => '$userId/profile.jpg';

  String? _extractStoragePath(String? storedValue) {
    if (storedValue == null || storedValue.trim().isEmpty) return null;
    final value = storedValue.trim();
    if (!value.startsWith('http')) return value;

    final marker = '/profile-photos/';
    final idx = value.indexOf(marker);
    if (idx == -1) return null;
    return value.substring(idx + marker.length);
  }

  Future<String?> resolveDisplayUrl(String userId, String? storedValue) async {
    final path = _extractStoragePath(storedValue);
    if (path == null || path.isEmpty) return storedValue;

    try {
      return await _supabase.storage
          .from(_bucket)
          .createSignedUrl(path, 60 * 60 * 24 * 7);
    } catch (_) {
      return _supabase.storage.from(_bucket).getPublicUrl(path);
    }
  }

  Future<XFile?> pickFromCamera() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxDimension.toDouble(),
      imageQuality: _quality,
    );
  }

  Future<XFile?> pickFromGallery() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxDimension.toDouble(),
      imageQuality: _quality,
    );
  }

  Future<String?> uploadPhoto(String userId, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.length > _maxSizeBytes) {
        throw Exception('Imagem muito grande. Máximo 5MB.');
      }

      final path = _storagePath(userId);
      final tmpFile = File('${Directory.systemTemp.path}/$userId-profile.jpg');
      await tmpFile.writeAsBytes(bytes, flush: true);

      await _supabase.storage.from(_bucket).upload(
            path,
            tmpFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      try {
        return await _supabase.storage
            .from(_bucket)
            .createSignedUrl(path, 60 * 60 * 24 * 7);
      } catch (_) {
        return _supabase.storage.from(_bucket).getPublicUrl(path);
      }
    } catch (e) {
      throw Exception('Falha ao fazer upload da foto: $e');
    }
  }

  Future<String?> uploadAndSavePhoto(String userId, XFile image) async {
    try {
      debugPrint('[profile_photo] Iniciando upload para usuário: $userId');
      final bytes = await image.readAsBytes();
      debugPrint('[profile_photo] Tamanho do arquivo: ${bytes.length} bytes');

      if (bytes.length > _maxSizeBytes) {
        throw Exception('Imagem muito grande. Máximo 5MB.');
      }

      final sessionUser = _supabase.auth.currentUser;
      if (sessionUser == null || sessionUser.id != userId) {
        throw Exception('Usuário não autenticado ou sessão inválida.');
      }

      final path = _storagePath(userId);
      final tmpFile = File('${Directory.systemTemp.path}/$userId-profile.jpg');
      await tmpFile.writeAsBytes(bytes, flush: true);

      debugPrint('[profile_photo] Upload para storage path: $path');
      await _supabase.storage.from(_bucket).upload(
            path,
            tmpFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      String displayUrl = '';
      try {
        displayUrl = await _supabase.storage
            .from(_bucket)
            .createSignedUrl(path, 60 * 60 * 24 * 7);
      } catch (e) {
        debugPrint('[profile_photo] Falha ao gerar signed url: $e');
        displayUrl = _supabase.storage.from(_bucket).getPublicUrl(path);
      }

      if (displayUrl.isEmpty) {
        throw Exception('Não foi possível gerar URL da imagem.');
      }

      final updateRes = await _supabase
          .from('profiles')
          .update({'photo_url': displayUrl})
          .eq('id', userId)
          .select()
          .maybeSingle();

      debugPrint('[profile_photo] profiles update result: $updateRes');
      if (updateRes == null) {
        throw Exception('Update profiles retornou null.');
      }

      return displayUrl;
    } catch (e, st) {
      debugPrint('[profile_photo] Erro ao enviar/atualizar foto: $e');
      debugPrint(st.toString());
      if (kDebugMode) {
        throw Exception('Falha ao fazer upload e salvar foto: $e');
      }
      throw Exception('Falha ao fazer upload e salvar foto.');
    }
  }

  Future<void> deletePhoto(String userId) async {
    try {
      final path = _storagePath(userId);
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (_) {
      // ignora erro se não existir
    }
  }
}
