/// Admin Settings Center screen — Phase 7.2.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_settings_repository.dart';

// Palette
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF131824);
const _kBorder = Color(0xFF1E2433);
const _kAccent = Color(0xFF6E8DFF);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kMuted = Color(0xFF8B94A7);

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.settings_outlined, color: _kAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kAccent,
          labelColor: Colors.white,
          unselectedLabelColor: _kMuted,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Identité'),
            Tab(text: 'Langues & Éducation'),
            Tab(text: 'Feature Flags'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _IdentityTab(),
          _LanguagesEducationTab(),
          _FeatureFlagsTab(),
          _MaintenanceTab(),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1 — Identity
// ============================================================

class _IdentityTab extends ConsumerStatefulWidget {
  const _IdentityTab();

  @override
  ConsumerState<_IdentityTab> createState() => _IdentityTabState();
}

class _IdentityTabState extends ConsumerState<_IdentityTab> {
  final _nameCtrl = TextEditingController();
  final _taglineFrCtrl = TextEditingController();
  final _taglineEnCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  void _initFrom(SettingsOptions opts) {
    if (_initialized) return;
    _nameCtrl.text = opts.identity.name;
    _taglineFrCtrl.text = opts.identity.tagline.fr;
    _taglineEnCtrl.text = opts.identity.tagline.en;
    _logoUrlCtrl.text = opts.identity.logoUrl;
    _colorCtrl.text = opts.identity.primaryColor;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(adminSettingsRepositoryProvider);
    try {
      await repo.updateSetting('app.name', _nameCtrl.text.trim());
      await repo.updateSetting('app.tagline', {
        'fr': _taglineFrCtrl.text.trim(),
        'en': _taglineEnCtrl.text.trim(),
      });
      await repo.updateSetting('app.logo_url', _logoUrlCtrl.text.trim());
      await repo.updateSetting('app.primary_color', _colorCtrl.text.trim());
      ref.invalidate(settingsOptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Identité mise à jour'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final optsAsync = ref.watch(settingsOptionsProvider);
    return optsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (opts) {
        _initFrom(opts);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  title: 'Identité de l\'application',
                  subtitle: 'Nom, tagline, logo et couleur primaire',
                ),
                const SizedBox(height: 20),
                _field('Nom', _nameCtrl),
                const SizedBox(height: 14),
                _field('Tagline (FR)', _taglineFrCtrl),
                const SizedBox(height: 14),
                _field('Tagline (EN)', _taglineEnCtrl),
                const SizedBox(height: 14),
                _field('Logo URL (vide = logo par défaut)', _logoUrlCtrl),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field('Couleur primaire (hex)', _colorCtrl)),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(_colorCtrl.text),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _saveButton(_save, _saving, 'Enregistrer l\'identité'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl) => TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _kMuted),
          filled: true,
          fillColor: _kCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kAccent),
          ),
        ),
      );
}

Color _parseColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  } catch (_) {}
  return _kAccent;
}

// ============================================================
// TAB 2 — Languages & Education
// ============================================================

class _LanguagesEducationTab extends ConsumerStatefulWidget {
  const _LanguagesEducationTab();

  @override
  ConsumerState<_LanguagesEducationTab> createState() =>
      _LanguagesEducationTabState();
}

class _LanguagesEducationTabState
    extends ConsumerState<_LanguagesEducationTab> {
  String _defaultLang = 'fr';
  List<String> _activeLangs = ['fr', 'en'];
  List<String> _systems = [];
  List<String> _subjects = [];
  List<String> _levels = [];
  List<int> _years = [];
  bool _initialized = false;

  void _initFrom(SettingsOptions opts) {
    if (_initialized) return;
    _defaultLang = opts.languages.defaultLang;
    _activeLangs = List.from(opts.languages.active);
    _systems = List.from(opts.educationSystems);
    _subjects = List.from(opts.subjects);
    _levels = List.from(opts.levels);
    _years = List.from(opts.years);
    _initialized = true;
  }

  Future<void> _saveAll() async {
    final repo = ref.read(adminSettingsRepositoryProvider);
    try {
      await repo.updateSetting('app.default_language', _defaultLang);
      await repo.updateSetting('app.active_languages', _activeLangs);
      await repo.updateSetting('education_systems', _systems);
      await repo.updateSetting('subjects', _subjects);
      await repo.updateSetting('levels', _levels);
      await repo.updateSetting('years', _years);
      ref.invalidate(settingsOptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Langues & éducation mises à jour'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final optsAsync = ref.watch(settingsOptionsProvider);
    return optsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (opts) {
        _initFrom(opts);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Langues',
                subtitle: 'Langue par défaut et langues actives',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Langue par défaut :',
                      style: TextStyle(color: _kMuted)),
                  const SizedBox(width: 12),
                  _dropdown<String>(
                    value: _defaultLang,
                    items: ['fr', 'en'],
                    onChanged: (v) => setState(() => _defaultLang = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Langues actives :',
                  style: TextStyle(color: _kMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['fr', 'en'].map((lang) {
                  final active = _activeLangs.contains(lang);
                  return FilterChip(
                    label: Text(lang.toUpperCase()),
                    selected: active,
                    onSelected: (v) {
                      setState(() {
                        if (v && !_activeLangs.contains(lang)) {
                          _activeLangs.add(lang);
                        } else if (!v) {
                          _activeLangs.remove(lang);
                        }
                      });
                    },
                    selectedColor: _kAccent.withOpacity(0.3),
                    backgroundColor: _kCard,
                    labelStyle: TextStyle(
                      color: active ? _kAccent : _kMuted,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Systèmes éducatifs',
                subtitle: '${_systems.length} systèmes',
              ),
              const SizedBox(height: 12),
              _chipListEditor(
                items: _systems,
                onAdd: (v) => setState(() => _systems.add(v)),
                onRemove: (v) => setState(() => _systems.remove(v)),
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Matières',
                subtitle: '${_subjects.length} matières',
              ),
              const SizedBox(height: 12),
              _chipListEditor(
                items: _subjects,
                onAdd: (v) => setState(() => _subjects.add(v)),
                onRemove: (v) => setState(() => _subjects.remove(v)),
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Niveaux',
                subtitle: '${_levels.length} niveaux',
              ),
              const SizedBox(height: 12),
              _chipListEditor(
                items: _levels,
                onAdd: (v) => setState(() => _levels.add(v)),
                onRemove: (v) => setState(() => _levels.remove(v)),
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Années',
                subtitle: '${_years.length} années',
              ),
              const SizedBox(height: 12),
              _chipListEditor(
                items: _years.map((y) => y.toString()).toList(),
                onAdd: (v) {
                  final y = int.tryParse(v);
                  if (y != null) setState(() => _years.add(y));
                },
                onRemove: (v) {
                  final y = int.tryParse(v);
                  if (y != null) setState(() => _years.remove(y));
                },
              ),
              const SizedBox(height: 32),
              _saveButton(_saveAll, false, 'Enregistrer tous les paramètres'),
            ],
          ),
        );
      },
    );
  }

  Widget _chipListEditor({
    required List<String> items,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) {
    final ctrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map((item) => Chip(
                    backgroundColor: _kCard,
                    label: Text(
                      item,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    onDeleted: () => onRemove(item),
                    deleteIcon: const Icon(Icons.close, size: 14, color: _kMuted),
                    side: const BorderSide(color: _kBorder),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    onAdd(v.trim());
                    ctrl.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Ajouter... (Entrée pour valider)',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 11),
                  isDense: true,
                  filled: true,
                  fillColor: _kCard,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: _kAccent),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  onAdd(ctrl.text.trim());
                  ctrl.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T) onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: _kCard,
          value: value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: items
              .map((it) => DropdownMenuItem<T>(value: it, child: Text('$it')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ============================================================
// TAB 3 — Feature Flags
// ============================================================

class _FeatureFlagsTab extends ConsumerStatefulWidget {
  const _FeatureFlagsTab();

  @override
  ConsumerState<_FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends ConsumerState<_FeatureFlagsTab> {
  @override
  Widget build(BuildContext context) {
    final optsAsync = ref.watch(settingsOptionsProvider);
    return optsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (opts) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Feature flags',
                subtitle:
                    'Activer/désactiver les fonctionnalités optionnelles en temps réel',
              ),
              const SizedBox(height: 20),
              for (final flag in opts.featureFlags)
                _FeatureFlagTile(flag: flag),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureFlagTile extends ConsumerStatefulWidget {
  const _FeatureFlagTile({required this.flag});
  final FeatureFlag flag;

  @override
  ConsumerState<_FeatureFlagTile> createState() => _FeatureFlagTileState();
}

class _FeatureFlagTileState extends ConsumerState<_FeatureFlagTile> {
  bool _toggling = false;

  Future<void> _toggle(bool newValue) async {
    setState(() => _toggling = true);
    try {
      await ref
          .read(adminSettingsRepositoryProvider)
          .updateFeatureFlag(widget.flag.key, newValue);
      ref.invalidate(settingsOptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${widget.flag.key} → ${newValue ? "activé" : "désactivé"}'),
            backgroundColor: _kGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            widget.flag.enabled ? Icons.toggle_on : Icons.toggle_off,
            color: widget.flag.enabled ? _kGreen : _kMuted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.flag.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.flag.description != null)
                  Text(
                    widget.flag.description!,
                    style: const TextStyle(color: _kMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
          _toggling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
                )
              : Switch(
                  value: widget.flag.enabled,
                  onChanged: _toggle,
                  activeColor: _kGreen,
                ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 4 — Maintenance
// ============================================================

class _MaintenanceTab extends ConsumerStatefulWidget {
  const _MaintenanceTab();

  @override
  ConsumerState<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends ConsumerState<_MaintenanceTab> {
  bool _enabled = false;
  final _messageCtrl = TextEditingController();
  DateTime? _eta;
  bool _initialized = false;

  void _initFrom(SettingsOptions opts) {
    if (_initialized) return;
    _enabled = opts.maintenance.enabled;
    _messageCtrl.text = opts.maintenance.message;
    _eta = opts.maintenance.eta;
    _initialized = true;
  }

  Future<void> _save() async {
    try {
      await ref.read(adminSettingsRepositoryProvider).setMaintenance(
            MaintenanceSettings(
              enabled: _enabled,
              message: _messageCtrl.text.trim(),
              eta: _eta,
            ),
          );
      ref.invalidate(settingsOptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enabled
                ? '⚠️ Maintenance ACTIVÉE'
                : '✅ Maintenance désactivée'),
            backgroundColor: _enabled ? _kOrange : _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final optsAsync = ref.watch(settingsOptionsProvider);
    return optsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (opts) {
        _initFrom(opts);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  title: 'Mode maintenance',
                  subtitle:
                      'Bloquer l\'application pour tous les users pendant les mises à jour',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _enabled
                        ? _kOrange.withOpacity(0.1)
                        : _kGreen.withOpacity(0.1),
                    border: Border.all(
                      color: _enabled
                          ? _kOrange.withOpacity(0.5)
                          : _kGreen.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _enabled ? Icons.warning_amber : Icons.check_circle,
                        color: _enabled ? _kOrange : _kGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _enabled
                              ? 'MAINTENANCE ACTIVÉE — l\'app est bloquée pour tous'
                              : 'App opérationnelle',
                          style: TextStyle(
                            color: _enabled ? _kOrange : _kGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                        activeColor: _kOrange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Message affiché aux utilisateurs',
                    labelStyle: const TextStyle(color: _kMuted),
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _eta == null
                            ? 'Aucune ETA définie'
                            : 'ETA : ${_formatDate(_eta!)}',
                        style: const TextStyle(color: _kMuted, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickEta,
                      icon: const Icon(Icons.calendar_today,
                          size: 16, color: _kAccent),
                      label: const Text('Choisir ETA',
                          style: TextStyle(color: _kAccent)),
                    ),
                    if (_eta != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: _kMuted),
                        onPressed: () => setState(() => _eta = null),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _saveButton(_save, false, 'Appliquer'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickEta() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _eta ?? DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eta ?? DateTime.now()),
    );
    if (t == null) return;
    setState(() {
      _eta = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }
}

// ============================================================
// SHARED
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _kMuted, fontSize: 11)),
      ],
    );
  }
}

Widget _saveButton(VoidCallback onTap, bool loading, String label) {
  return SizedBox(
    height: 44,
    child: FilledButton.icon(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(backgroundColor: _kAccent),
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save, size: 18),
      label: Text(label),
    ),
  );
}

String _formatDate(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
