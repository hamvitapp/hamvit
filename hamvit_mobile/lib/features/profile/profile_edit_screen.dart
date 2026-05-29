import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/supabase_provider.dart';
import '../../shared/widgets/hamvit_date_field.dart';
import '../auth/providers/auth_provider.dart';
import '../evolution/evolution_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import 'services/profile_photo_service.dart';
import 'widgets/profile_photo_widget.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();

  String _sex = 'não informado';
  String _activityLevel = 'moderada';
  String? _birthIso;
  String? _photoUrl;
  bool _uploading = false;
  bool _photoChanged = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    final onboarding = ref.read(onboardingProfileProvider);

    _nameCtrl.text = profile?.displayName ?? '';
    _photoUrl = profile?.photoUrl;
    _birthIso = onboarding.birthDateIso;
    _birthCtrl.text = onboarding.birthDateIso == null ? '' : onboarding.birthDateIso!.split('-').reversed.join('/');
    _sex = onboarding.biologicalSex ?? 'não informado';
    _heightCtrl.text = onboarding.heightCm?.toString() ?? '';
    _weightCtrl.text = onboarding.weightKg?.toString() ?? '';
    _targetWeightCtrl.text = onboarding.targetWeightKg?.toString() ?? '';
    _activityLevel = onboarding.activityLevel ?? 'moderada';
    _objectiveCtrl.text = onboarding.objective ?? '';

    _refreshProfileFromServer();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final cropped = await ImageCropper.platform.cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: const Color(0xFF071A2D),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF071A2D),
          statusBarColor: const Color(0xFF071A2D),
          activeControlsWidgetColor: const Color(0xFF00B4D8),
          cropFrameColor: Colors.white,
          cropFrameStrokeWidth: 2,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
      ],
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
    );
    if (cropped == null) return;

    // Upload para Supabase Storage
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _uploading = true);

    try {
      final service = ProfilePhotoService(client);
      final xfile = XFile(cropped.path);
      final url = await service.uploadAndSavePhoto(user.id, xfile);

      if (url != null) {
        // Atualiza UI imediatamente e marca mudança
        setState(() {
          _photoUrl = url;
          _photoChanged = true;
        });

        // Atualiza apenas a UI local do editor; evitamos chamar
        // `bootstrap()` (pode disparar efeitos de navegação). A
        // mudança global será propagada em próximo refresh.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto atualizada com sucesso.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final message = e?.toString() ?? 'Não foi possível atualizar sua foto.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar foto: $message')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Foto de perfil',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 24),
              title: const Text('Tirar foto', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndCropImage(ImageSource.camera);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              hoverColor: Colors.white10,
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white70, size: 24),
              title: const Text('Escolher da galeria', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndCropImage(ImageSource.gallery);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              hoverColor: Colors.white10,
            ),
            if (_photoUrl != null && _photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                title: const Text('Remover foto', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final client = ref.read(supabaseClientProvider);
                  final user = ref.read(currentUserProvider);
                  if (client == null || user == null) return;

                  try {
                    final service = ProfilePhotoService(client);
                    await service.deletePhoto(user.id);
                    setState(() {
                      _photoUrl = null;
                      _photoChanged = true;
                    });
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Não foi possível remover sua foto.')),
                    );
                  }
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                hoverColor: Colors.white10,
              ),
            ],
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white54, size: 24),
              title: const Text('Cancelar', style: TextStyle(color: Colors.white54, fontSize: 16)),
              onTap: () => Navigator.pop(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              hoverColor: Colors.white10,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProfileFromServer() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (client == null || user == null) return;

    try {
      final row = await client
          .from('profiles')
          .select('display_name, full_name, photo_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || row == null) return;
      final service = ProfilePhotoService(client);
      final resolvedPhotoUrl =
          await service.resolveDisplayUrl(user.id, row['photo_url'] as String?);
      setState(() {
        final displayName = (row['display_name'] as String?) ?? (row['full_name'] as String?) ?? '';
        if (displayName.trim().isNotEmpty) {
          _nameCtrl.text = displayName.trim();
        }
        _photoUrl = resolvedPhotoUrl;
      });
    } catch (_) {
      // Keep local state if remote refresh fails.
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final client = ref.read(supabaseClientProvider);
    final notifier = ref.read(onboardingProfileProvider.notifier);

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final height = int.tryParse(_heightCtrl.text.trim());
    final targetWeight = double.tryParse(_targetWeightCtrl.text.replaceAll(',', '.'));
    final objective = _objectiveCtrl.text.trim();

    if (weight == null || height == null || objective.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, objetivo, peso e altura com valores validos.')),
      );
      return;
    }

    if (client != null && user != null) {
      try {
        final updateData = <String, dynamic>{
          'display_name': _nameCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
        };
        if (_photoChanged) {
          updateData['photo_url'] = _photoUrl;
        }
        await client.from('profiles').update(updateData).eq('id', user.id);
      } catch (_) {}
    }

    await notifier.saveGeneralProfile(objective: objective);
    await notifier.saveActivityPreferences(
      activityLevel: _activityLevel,
      limitations: null,
      trainingPreference: null,
      availableDays: const [],
      availableMinutes: null,
    );
    await notifier.saveBodyData(
      weightKg: weight,
      heightCm: height,
      targetWeightKg: targetWeight,
      birthDateIso: _birthIso,
      biologicalSex: _sex,
    );
    ref.invalidate(evolutionDashboardProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);
    final isSaving = state.isSaving || _uploading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Foto de perfil no topo
        Center(
          child: Column(
            children: [
              ProfilePhotoWidget(
                photoUrl: _photoUrl,
                displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
                size: 110,
                editable: true,
                onTap: _showPhotoPicker,
              ),
              if (_uploading) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B4D8)),
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                onPressed: _showPhotoPicker,
                child: Text(
                  _photoUrl != null ? 'Alterar foto' : 'Adicionar foto',
                  style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Editar perfil', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 8),
        HamvitDateField(
          label: 'Data de nascimento',
          controller: _birthCtrl,
          onIsoChanged: (iso) => _birthIso = iso,
          lastDate: DateTime.now(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _sex,
          decoration: const InputDecoration(labelText: 'Sexo biologico'),
          items: const [
            DropdownMenuItem(value: 'não informado', child: Text('Nao informado')),
            DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'intersexo', child: Text('Intersexo')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _sex = v);
          },
        ),
        const SizedBox(height: 8),
        TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Altura (cm)')),
        const SizedBox(height: 8),
        TextField(controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso atual (kg)')),
        const SizedBox(height: 8),
        TextField(controller: _targetWeightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso desejado (kg)')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(labelText: 'Nivel de atividade'),
          items: const [
            DropdownMenuItem(value: 'sedentaria', child: Text('Sedentaria')),
            DropdownMenuItem(value: 'leve', child: Text('Leve')),
            DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
            DropdownMenuItem(value: 'alta', child: Text('Alta')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _activityLevel = v);
          },
        ),
        const SizedBox(height: 8),
        TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Objetivo principal')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: isSaving ? null : _save,
          child: Text(isSaving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
