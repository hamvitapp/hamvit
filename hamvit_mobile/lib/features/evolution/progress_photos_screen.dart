import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/hamvit_date_utils.dart';
import 'evolution_models.dart';

class ProgressPhotosScreen extends StatefulWidget {
  final List<ProgressPhotoEntry> photos;
  final Future<void> Function(String path, String? notes) onAddPhoto;

  const ProgressPhotosScreen({
    super.key,
    required this.photos,
    required this.onAddPhoto,
  });

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final _picker = ImagePicker();
  bool _saving = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    if (!mounted) return;

    final noteCtrl = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observacao opcional'),
        content: TextField(
          controller: noteCtrl,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Nota da foto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Pular')),
          FilledButton(onPressed: () => Navigator.of(context).pop(noteCtrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );

    setState(() => _saving = true);
    try {
      await widget.onAddPhoto(picked.path, note);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos corporais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Acompanhe sua evolucao no seu ritmo.'),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_saving ? 'Salvando...' : 'Adicionar foto'),
          ),
          const SizedBox(height: 12),
          if (widget.photos.isEmpty)
            const Text('Sem fotos registradas ainda.')
          else
            ...widget.photos.map(
              (photo) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Text('Imagem indisponivel'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(HamvitDateUtils.formatDateBr(photo.takenAt)),
                      if (photo.notes != null && photo.notes!.isNotEmpty)
                        Text(photo.notes!),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}