import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_ai_repository.dart';

class AdminAICenterScreen extends ConsumerStatefulWidget {
  const AdminAICenterScreen({super.key});

  @override
  ConsumerState<AdminAICenterScreen> createState() => _AdminAICenterScreenState();
}

class _AdminAICenterScreenState extends ConsumerState<AdminAICenterScreen> {
  final _promptCtrl = TextEditingController();
  final _testMsgCtrl = TextEditingController();
  final _maxTokensCtrl = TextEditingController();

  String? _model;
  double _temperature = 0.5;
  bool _saving = false;
  bool _testing = false;
  AITestResult? _lastTest;
  bool _promptDirty = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    _testMsgCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromConfig(AIConfig cfg) {
    if (_promptCtrl.text.isEmpty) {
      _promptCtrl.text = cfg.systemPrompt;
      _model = cfg.model;
      _temperature = cfg.temperature;
      _maxTokensCtrl.text = cfg.maxTokens.toString();
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(adminAIRepositoryProvider).updateConfig(
            systemPrompt: _promptCtrl.text.trim(),
            model: _model,
            temperature: _temperature,
            maxTokens: int.tryParse(_maxTokensCtrl.text) ?? 1200,
          );
      ref.invalidate(aiConfigProvider);
      if (mounted) {
        setState(() => _promptDirty = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Config sauvegardée (live)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publier une version'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
    if (ok != true) {
      notesCtrl.dispose();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final v = await ref
          .read(adminAIRepositoryProvider)
          .publish(notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
      ref.invalidate(aiVersionsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Version v${v.version} publiée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      notesCtrl.dispose();
    }
  }

  Future<void> _test() async {
    if (_testMsgCtrl.text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _testing = true;
      _lastTest = null;
    });
    try {
      final result = await ref.read(adminAIRepositoryProvider).test(
            message: _testMsgCtrl.text.trim(),
            systemPrompt: _promptCtrl.text.trim(),
            model: _model,
            temperature: _temperature,
            maxTokens: int.tryParse(_maxTokensCtrl.text),
          );
      if (mounted) setState(() => _lastTest = result);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur test: $e')));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _activateVersion(AIConfigVersion v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Activer v${v.version} ?'),
        content: Text(
          'Le prompt sera remplacé par la version ${v.version} '
          'publiée le ${v.publishedAt.day}/${v.publishedAt.month}/${v.publishedAt.year}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminAIRepositoryProvider).activateVersion(v.id);
      ref.invalidate(aiConfigProvider);
      if (mounted) {
        _promptCtrl.text = v.systemPrompt;
        _model = v.model;
        _temperature = v.temperature;
        _maxTokensCtrl.text = v.maxTokens.toString();
        setState(() => _promptDirty = false);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Version v${v.version} activée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(aiConfigProvider);
    final versionsAsync = ref.watch(aiVersionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(aiConfigProvider);
        ref.invalidate(aiVersionsProvider);
        await ref.read(aiConfigProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('AI Control Center',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, size: 12, color: Colors.purple),
                    SizedBox(width: 6),
                    Text('Live',
                        style: TextStyle(
                            color: Colors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Modifie le comportement de l\'agent IA sans redéploiement.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          configAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (cfg) {
              _hydrateFromConfig(cfg);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Config card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Configuration',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _model,
                                  decoration: const InputDecoration(
                                    labelText: 'Modèle',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'gemini-3.1-flash-lite',
                                        child: Text('gemini-3.1-flash-lite')),
                                    DropdownMenuItem(
                                        value: 'gemini-2.5-flash',
                                        child: Text('gemini-2.5-flash')),
                                    DropdownMenuItem(
                                        value: 'gemini-2.5-pro',
                                        child: Text('gemini-2.5-pro')),
                                  ],
                                  onChanged: (v) => setState(() => _model = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _maxTokensCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Max tokens',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Température : ${_temperature.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Expanded(
                                child: Slider(
                                  value: _temperature,
                                  min: 0,
                                  max: 2,
                                  divisions: 20,
                                  label: _temperature.toStringAsFixed(2),
                                  onChanged: (v) =>
                                      setState(() => _temperature = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prompt editor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('System prompt',
                                  style: theme.textTheme.titleMedium),
                              const Spacer(),
                              if (_promptDirty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Non sauvegardé',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _promptCtrl,
                            maxLines: 12,
                            decoration: const InputDecoration(
                              hintText: 'Tu es MINDORA...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              if (!_promptDirty) {
                                setState(() => _promptDirty = true);
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_promptCtrl.text.length} caractères (min 20)',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.save, size: 16),
                                label: const Text('Sauvegarder'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _publish,
                                icon: const Icon(Icons.publish, size: 16),
                                label: const Text('Publier une version'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _promptCtrl.text = cfg.systemPrompt;
                                  setState(() => _promptDirty = false);
                                },
                                icon: const Icon(Icons.restore, size: 16),
                                label: const Text('Restaurer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Test panel
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tester avant publication',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Le message sera envoyé avec le prompt actuel '
                            '(modifié ou sauvegardé).',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _testMsgCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Message test',
                              hintText: 'Explique-moi Pythagore...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _testing ? null : _test,
                            icon: _testing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Tester'),
                          ),
                          if (_lastTest != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.smart_toy,
                                          size: 16, color: Colors.purple),
                                      const SizedBox(width: 6),
                                      Text('Réponse IA',
                                          style: theme.textTheme.labelMedium),
                                      const Spacer(),
                                      Text(
                                        '${_lastTest!.elapsedMs} ms',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _lastTest!.response,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_lastTest!.usage['total_tokens'] ?? 0} tokens · ${_lastTest!.provider}/${_lastTest!.model}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Versions history
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Historique des versions',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          versionsAsync.when(
                            loading: () => const Center(
                                child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            )),
                            error: (e, _) => Text('Erreur: $e'),
                            data: (versions) {
                              if (versions.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    'Aucune version publiée pour l\'instant.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              }
                              return Column(
                                children: versions.map((v) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: theme
                                          .colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      child: Text('v${v.version}',
                                          style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(
                                      v.notes ?? '(sans notes)',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      '${v.publishedAt.day}/${v.publishedAt.month}/${v.publishedAt.year} · '
                                      '${v.model} · temp=${v.temperature.toStringAsFixed(2)}',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    trailing: OutlinedButton(
                                      onPressed: () => _activateVersion(v),
                                      child: const Text('Activer'),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
