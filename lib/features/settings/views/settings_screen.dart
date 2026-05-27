import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/postgres_sync_service.dart';
import '../providers/settings_provider.dart';
import '../../gallery/providers/yolo_face_provider.dart';
import '../../gallery/providers/gallery_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control Center',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust workspace variables and synchronize local storage archives',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.paddingExtraLarge),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: const [
                ProfileCard(),
                SizedBox(height: AppConstants.paddingLarge),
                LlmCard(),
                SizedBox(height: AppConstants.paddingLarge),
                YoloConfigCard(),
                SizedBox(height: AppConstants.paddingLarge),
                PostgresSyncCard(),
                SizedBox(height: AppConstants.paddingLarge),
                StorageCard(),
                SizedBox(height: AppConstants.paddingLarge),
                ToggleCard(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// Standalone Host Profile configuration widget.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(provider.profileImage),
          ),
          const SizedBox(width: AppConstants.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chronicle Host',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active Local Session',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final controller = TextEditingController(text: provider.username);
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E38),
                  title: const Text('Update Host Profile'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        controller.dispose();
                        Navigator.pop(dialogCtx);
                      },
                      child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.updateUsername(controller.text);
                        controller.dispose();
                        Navigator.pop(dialogCtx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accent),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: AppConstants.textPrimary,
              elevation: 0,
            ),
            child: const Text('Edit Name'),
          ),
        ],
      ),
    );
  }
}

/// Performance-isolated local VLM model configuration.
/// Uses a StatefulWidget to prevent cursor resetting jumps during typing!
class LlmCard extends StatefulWidget {
  const LlmCard({super.key});

  @override
  State<LlmCard> createState() => _LlmCardState();
}

class _LlmCardState extends State<LlmCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
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
    final provider = context.watch<SettingsProvider>();
    final galleryProv = context.watch<GalleryProvider>();

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
                  color: galleryProv.isLlmAvailable
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: galleryProv.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
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
                        color: galleryProv.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      galleryProv.isLlmAvailable ? 'VLM ONLINE' : 'VLM OFFLINE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: galleryProv.isLlmAvailable ? Colors.greenAccent : Colors.redAccent,
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
                  onChanged: (val) => provider.updateOllamaUrl(val),
                  decoration: const InputDecoration(
                    labelText: 'Local Ollama URL Endpoint',
                    hintText: 'e.g. http://localhost:11434',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: galleryProv.pulledModels.isNotEmpty
                    ? DropdownButtonFormField<String>(
                        initialValue: galleryProv.pulledModels.contains(provider.ollamaModel)
                            ? provider.ollamaModel
                            : galleryProv.pulledModels.first,
                        decoration: const InputDecoration(
                          labelText: 'Installed VLM Models (Auto-Detected)',
                        ),
                        dropdownColor: const Color(0xFF1E1E35),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (newModel) {
                          if (newModel != null) {
                            provider.updateOllamaModel(newModel);
                          }
                        },
                        items: galleryProv.pulledModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                      )
                    : TextField(
                        controller: _modelController,
                        onChanged: (val) => provider.updateOllamaModel(val),
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
            onChanged: (val) => provider.toggleAutoTag(val),
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

/// Isolated YOLO edge model settings.
class YoloConfigCard extends StatelessWidget {
  const YoloConfigCard({super.key});

  @override
  Widget build(BuildContext context) {
    final yoloProv = context.watch<YoloFaceProvider>();
    final settingsProv = context.watch<SettingsProvider>();

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
            children: const [
              Icon(Icons.face_outlined, color: AppConstants.secondary),
              SizedBox(width: 8),
              Text(
                'YOLO v8 Face Classifier Weights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Simulate whether the edge neural weights file (yolov8n-face.tflite) is successfully loaded into active application memory.',
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Edge Weights Loaded', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(
              yoloProv.isYoloAvailable 
                  ? 'Processor active - Bounding box overlays online'
                  : 'Processor offline - Face identification paused',
              style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
            ),
            value: yoloProv.isYoloAvailable,
            activeThumbColor: AppConstants.secondary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => yoloProv.setYoloAvailable(val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Independent YOLO Processing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text(
              'Process face detection immediately on image pick, without waiting for VLM auto-tagging to complete.',
              style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
            ),
            value: settingsProv.yoloIndependent,
            activeThumbColor: AppConstants.secondary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => settingsProv.toggleYoloIndependent(val),
          ),
        ],
      ),
    );
  }
}

/// Standalone PostgreSQL database sync card.
/// Uses a StatefulWidget to correctly manage and release ScrollController!
class PostgresSyncCard extends StatefulWidget {
  const PostgresSyncCard({super.key});

  @override
  State<PostgresSyncCard> createState() => _PostgresSyncCardState();
}

class _PostgresSyncCardState extends State<PostgresSyncCard> {
  late final ScrollController _terminalController;

  @override
  void initState() {
    super.initState();
    _terminalController = ScrollController();
  }

  @override
  void dispose() {
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pgSync = context.watch<PostgresSyncService>();

    // Autoscroll db terminal to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalController.hasClients) {
        _terminalController.jumpTo(_terminalController.position.maxScrollExtent);
      }
    });

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
                  Icon(Icons.storage_outlined, color: AppConstants.accent),
                  SizedBox(width: 8),
                  Text(
                    'PostgreSQL Relational Sync Center',
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
                  color: pgSync.isConnected
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: pgSync.isConnected ? Colors.greenAccent : Colors.redAccent,
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
                        color: pgSync.isConnected ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pgSync.isConnected ? 'SYNC ACTIVE' : 'SYNC PAUSED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: pgSync.isConnected ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Streams newly ingested vision tags, short/long summaries, array keywords, and YOLO face annotations to an external PostgreSQL database.',
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Postgres Sync Pipeline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('localhost:5432/chronicle', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                  value: pgSync.isConnected,
                  activeThumbColor: AppConstants.accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    pgSync.toggleConnection(val);
                    if (val) {
                      pgSync.processSyncQueue();
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pgSync.sqlSchemaMigration));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PostgreSQL Schema creation DDL copied to clipboard!'),
                      backgroundColor: AppConstants.accent,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy SQL Schema', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: AppConstants.textPrimary,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSyncStat('Database Transactions', '${pgSync.syncedRecords} rows synced'),
              _buildSyncStat('Offline Queue Buffer', '${pgSync.syncQueue.length} statements'),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'LIVE DATABASE SYNC STREAM LOG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppConstants.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: const Color(0xFF070710),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'sql_sync_terminal_v1.0',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppConstants.textMuted),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: AppConstants.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Clear sync log',
                      onPressed: () => pgSync.clearLogs(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView.builder(
                    controller: _terminalController,
                    itemCount: pgSync.syncLogs.length,
                    itemBuilder: (context, index) {
                      final log = pgSync.syncLogs[index];
                      Color color = AppConstants.textSecondary;
                      if (log.startsWith('[Success]')) {
                        color = Colors.greenAccent;
                      } else if (log.startsWith('[Error]') || log.startsWith('[Database OFFLINE]')) {
                        color = Colors.redAccent;
                      } else if (log.startsWith('[Execute]')) {
                        color = Colors.blueAccent;
                      } else if (log.startsWith('INSERT INTO') || log.startsWith('ON CONFLICT')) {
                        color = Colors.amberAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStat(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

/// Standalone storage display.
class StorageCard extends StatelessWidget {
  const StorageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

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
                  Icon(Icons.cloud_queue, color: AppConstants.accent),
                  SizedBox(width: 8),
                  Text(
                    'Workspace Cloud Quota',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                provider.storageLimit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 2.4 / 15.0,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accent),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Automatic sync active',
                style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
              TextButton(
                onPressed: () {
                  provider.simulateStorageIncrease(100);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synchronized cloud database space!')),
                  );
                },
                child: const Text('Sync Now', style: TextStyle(color: AppConstants.accent)),
              )
            ],
          ),
        ],
      ),
    );
  }
}

/// Standalone switch configuration for theme and notification configurations.
class ToggleCard extends StatelessWidget {
  const ToggleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

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
          const Text(
            'General Switches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          SwitchListTile(
            title: const Text('Vibrant Dark Aesthetics'),
            subtitle: const Text('Toggle high-contrast premium twilight styles'),
            value: provider.darkMode,
            activeThumbColor: AppConstants.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.toggleDarkMode(val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable System Audio/Notifiers'),
            subtitle: const Text('Send audio confirmations on media pick/scaffold'),
            value: provider.enableNotifications,
            activeThumbColor: AppConstants.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.toggleNotifications(val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Preferred Layout'),
            subtitle: const Text('Toggle default media presentation'),
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              icon: Icon(
                provider.gridMode ? Icons.grid_view : Icons.view_list,
                color: AppConstants.primary,
              ),
              onPressed: () => provider.toggleLayoutMode(),
            ),
          )
        ],
      ),
    );
  }
}
