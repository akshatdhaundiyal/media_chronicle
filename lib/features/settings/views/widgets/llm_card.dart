import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';

class LlmCard extends ConsumerStatefulWidget {
  const LlmCard({super.key});

  @override
  ConsumerState<LlmCard> createState() => _LlmCardState();
}

class _LlmCardState extends ConsumerState<LlmCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final provider = ref.read(settingsProvider);
    _urlController = TextEditingController(text: provider.ollamaUrl);
    _modelController = TextEditingController(text: provider.ollamaModel);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(settingsProvider);
    final galleryState = ref.watch(galleryProvider);

    // Safely sync controller texts if changed externally
    if (_urlController.text != provider.ollamaUrl) {
      _urlController.text = provider.ollamaUrl;
    }
    if (_modelController.text != provider.ollamaModel) {
      _modelController.text = provider.ollamaModel;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.psychology_outlined, color: AppConstants.primary),
                  SizedBox(width: 8),
                  Text(
                    'Gemma 4 VLM Core Config',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: galleryState.isLlmAvailable
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: galleryState.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: galleryState.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      galleryState.isLlmAvailable ? 'VLM ONLINE' : 'VLM OFFLINE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: galleryState.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateOllamaUrl(val),
                  decoration: const InputDecoration(
                    labelText: 'Local Ollama URL Endpoint',
                    hintText: 'e.g. http://localhost:11434',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: galleryState.pulledModels.isNotEmpty
                    ? DropdownButtonFormField<String>(
                        initialValue: galleryState.pulledModels.contains(provider.ollamaModel)
                            ? provider.ollamaModel
                            : galleryState.pulledModels.first,
                        decoration: const InputDecoration(
                          labelText: 'Installed VLM Models (Auto-Detected)',
                        ),
                        dropdownColor: const Color(0xFF1E1E35),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (newModel) {
                          if (newModel != null) {
                            ref.read(settingsProvider.notifier).updateOllamaModel(newModel);
                          }
                        },
                        items: galleryState.pulledModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                      )
                    : TextField(
                        controller: _modelController,
                        onChanged: (val) => ref.read(settingsProvider.notifier).updateOllamaModel(val),
                        decoration: const InputDecoration(
                          labelText: 'Vision VLM Model Name',
                          hintText: 'e.g. gemma4, paligemma, llava',
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Auto-Tag New Elements'),
            subtitle: const Text('Asynchronously stream image files to local LLM on pick'),
            value: provider.autoTagEnabled,
            activeThumbColor: AppConstants.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleAutoTag(val),
          ),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endpoint Diagnosis',
                style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
              ElevatedButton.icon(
                onPressed: () => _testOllamaConnection(context, provider.ollamaUrl),
                icon: const Icon(Icons.cast_connected, size: 14),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primary.withValues(alpha: 0.2),
                  foregroundColor: AppConstants.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppConstants.primary, width: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testOllamaConnection(BuildContext context, String url) async {
    try {
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final uri = Uri.parse(cleanUrl);
      
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      
      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ollama Endpoint Online! Server responded successfully from $cleanUrl.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Endpoint Offline: Server returned code ${response.statusCode}.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Failed: Could not connect to $url. Visual fallbacks active.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
