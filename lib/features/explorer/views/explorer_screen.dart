import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final String type; // 'code' | 'config' | 'doc' | 'other'
  final String size;
  final String summary;
  bool isExpanded;
  final List<FileNode> children;

  FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.type = 'other',
    this.size = '0 B',
    this.summary = '',
    this.isExpanded = false,
    this.children = const [],
  });
}

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  late FileNode _rootNode;
  FileNode? _selectedFile;

  @override
  void initState() {
    super.initState();
    _buildWorkspaceTree();
  }

  void _buildWorkspaceTree() {
    _rootNode = FileNode(
      name: 'media_chronicle',
      path: 'd:/lab/projects/media_chronicle',
      isDirectory: true,
      isExpanded: true,
      children: [
        FileNode(
          name: 'lib',
          path: 'lib/',
          isDirectory: true,
          isExpanded: true,
          children: [
            FileNode(
              name: 'main.dart',
              path: 'lib/main.dart',
              type: 'code',
              size: '1.5 KB',
              summary: 'Core orchestrator setting up MultiProvider and MaterialApp with zero logic.',
            ),
            FileNode(
              name: 'state',
              path: 'lib/state/',
              isDirectory: true,
              children: [
                FileNode(
                  name: 'app_state.dart',
                  path: 'lib/state/app_state.dart',
                  type: 'code',
                  size: '1.6 KB',
                  summary: 'Tracks top navigation tabs, active search keywords, active group categories, and album selections.',
                ),
              ],
            ),
            FileNode(
              name: 'core',
              path: 'lib/core/',
              isDirectory: true,
              children: [
                FileNode(
                  name: 'constants',
                  path: 'lib/core/constants/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'app_constants.dart',
                      path: 'lib/core/constants/app_constants.dart',
                      type: 'code',
                      size: '1.8 KB',
                      summary: 'Unified design system tokens including dark HSL gradients, spacing metrics, and terminal colors.',
                    ),
                  ],
                ),
                FileNode(
                  name: 'theme',
                  path: 'lib/core/theme/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'app_theme.dart',
                      path: 'lib/core/theme/app_theme.dart',
                      type: 'code',
                      size: '2.7 KB',
                      summary: 'Configures dark Material theme metrics and binds custom Outfit Google Font weights.',
                    ),
                  ],
                ),
                FileNode(
                  name: 'utils',
                  path: 'lib/core/utils/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'media_helper.dart',
                      path: 'lib/core/utils/media_helper.dart',
                      type: 'code',
                      size: '4.2 KB',
                      summary: 'Cross-platform file-picker and camera-capture wrapper, including visual group icon mapping utilities.',
                    ),
                    FileNode(
                      name: 'llm_helper.dart',
                      path: 'lib/core/utils/llm_helper.dart',
                      type: 'code',
                      size: '10.8 KB',
                      summary: 'Ollama local Vision LLM (Gemma 4) connector. Handles Base64 translation and smart offline fallbacks.',
                    ),
                    FileNode(
                      name: 'postgres_sync_service.dart',
                      path: 'lib/core/utils/postgres_sync_service.dart',
                      type: 'code',
                      size: '7.9 KB',
                      summary: 'Relational PostgreSQL background synchronization service for offline-first transactional integrity.',
                    ),
                  ],
                ),
              ],
            ),
            FileNode(
              name: 'features',
              path: 'lib/features/',
              isDirectory: true,
              isExpanded: true,
              children: [
                FileNode(
                  name: 'dashboard',
                  path: 'lib/features/dashboard/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'views',
                      path: 'lib/features/dashboard/views/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'dashboard_shell.dart',
                          path: 'lib/features/dashboard/views/dashboard_shell.dart',
                          type: 'code',
                          size: '21.2 KB',
                          summary: 'Responsive navigation scaffold shell displaying logo, user profiles, adaptive sidebars, and storage meters.',
                        ),
                      ],
                    ),
                  ],
                ),
                FileNode(
                  name: 'gallery',
                  path: 'lib/features/gallery/',
                  isDirectory: true,
                  isExpanded: true,
                  children: [
                    FileNode(
                      name: 'models',
                      path: 'lib/features/gallery/models/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'media_item.dart',
                          path: 'lib/features/gallery/models/media_item.dart',
                          type: 'code',
                          size: '1.1 KB',
                          summary: 'Fully immutable model capturing vision features: face labels, places, dates, and categories.',
                        ),
                        FileNode(
                          name: 'detected_face.dart',
                          path: 'lib/features/gallery/models/detected_face.dart',
                          type: 'code',
                          size: '1.2 KB',
                          summary: 'Fully immutable detected face bounding boxes tracking unmodifiable coordinate sets and 2D dense embeddings.',
                        ),
                        FileNode(
                          name: 'album.dart',
                          path: 'lib/features/gallery/models/album.dart',
                          type: 'code',
                          size: '0.4 KB',
                          summary: 'Custom folder album data model tracking associated item ID collections.',
                        ),
                      ],
                    ),
                    FileNode(
                      name: 'providers',
                      path: 'lib/features/gallery/providers/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'gallery_provider.dart',
                          path: 'lib/features/gallery/providers/gallery_provider.dart',
                          type: 'code',
                          size: '9.7 KB',
                          summary: 'Local VLM queue worker managing async Ollama requests and album folder structures.',
                        ),
                        FileNode(
                          name: 'yolo_face_provider.dart',
                          path: 'lib/features/gallery/providers/yolo_face_provider.dart',
                          type: 'code',
                          size: '14.7 KB',
                          summary: 'Simulated edge YOLO recognizer carrying training logs and identity timeline backpropagation loops.',
                        ),
                      ],
                    ),
                    FileNode(
                      name: 'views',
                      path: 'lib/features/gallery/views/',
                      isDirectory: true,
                      isExpanded: true,
                      children: [
                        FileNode(
                          name: 'gallery_screen.dart',
                          path: 'lib/features/gallery/views/gallery_screen.dart',
                          type: 'code',
                          size: '11.5 KB',
                          summary: 'Lean Vue-like gallery screen coordinator composing independent visual sub-widgets.',
                        ),
                        FileNode(
                          name: 'yolo_face_screen.dart',
                          path: 'lib/features/gallery/views/yolo_face_screen.dart',
                          type: 'code',
                          size: '42.3 KB',
                          summary: 'Face identification hub showcasing 2D dense vector clusters and model training backpropagation log terminals.',
                        ),
                        FileNode(
                          name: 'widgets',
                          path: 'lib/features/gallery/views/widgets/',
                          isDirectory: true,
                          children: [
                            FileNode(
                              name: 'gallery_toolbar.dart',
                              path: 'lib/features/gallery/views/widgets/gallery_toolbar.dart',
                              type: 'code',
                              size: '3.5 KB',
                              summary: 'Manages batch selections, folder movement, VLM re-runs, and upload action buttons.',
                            ),
                            FileNode(
                              name: 'gallery_quick_panel.dart',
                              path: 'lib/features/gallery/views/widgets/gallery_quick_panel.dart',
                              type: 'code',
                              size: '6.2 KB',
                              summary: 'Exhibits active album folder horizontal chips and local VLM ingestion progress bars.',
                            ),
                            FileNode(
                              name: 'gallery_card.dart',
                              path: 'lib/features/gallery/views/widgets/gallery_card.dart',
                              type: 'code',
                              size: '7.2 KB',
                              summary: 'Exhibits individual visual media cards, optimized with Selector to rebuild on O(1) specific annotations changes.',
                            ),
                            FileNode(
                              name: 'media_detail_dialog.dart',
                              path: 'lib/features/gallery/views/widgets/media_detail_dialog.dart',
                              type: 'code',
                              size: '8.1 KB',
                              summary: 'Displays visual asset, interactive overlay face bounding boxes, and detailed scene narrative.',
                            ),
                            FileNode(
                              name: 'face_labeling_dialog.dart',
                              path: 'lib/features/gallery/views/widgets/face_labeling_dialog.dart',
                              type: 'code',
                              size: '4.5 KB',
                              summary: 'Shared identify face dialog checking for chronological age growth progression confirmation.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                FileNode(
                  name: 'settings',
                  path: 'lib/features/settings/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'providers',
                      path: 'lib/features/settings/providers/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'settings_provider.dart',
                          path: 'lib/features/settings/providers/settings_provider.dart',
                          type: 'code',
                          size: '1.9 KB',
                          summary: 'Keeps storage byte limits, dark modes, and local Ollama endpoint connection properties.',
                        ),
                      ],
                    ),
                    FileNode(
                      name: 'views',
                      path: 'lib/features/settings/views/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'settings_screen.dart',
                          path: 'lib/features/settings/views/settings_screen.dart',
                          type: 'code',
                          size: '31.1 KB',
                          summary: 'Decomposed Settings screen showcasing standalone profile, LLM configurations, and database terminals.',
                        ),
                      ],
                    ),
                  ],
                ),
                FileNode(
                  name: 'stories',
                  path: 'lib/features/stories/',
                  isDirectory: true,
                  children: [
                    FileNode(
                      name: 'views',
                      path: 'lib/features/stories/views/',
                      isDirectory: true,
                      children: [
                        FileNode(
                          name: 'stories_screen.dart',
                          path: 'lib/features/stories/views/stories_screen.dart',
                          type: 'code',
                          size: '26.6 KB',
                          summary: 'Generates creative memory logs by reading visual VLM descriptions and composing textual narratives.',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        FileNode(
          name: 'docs',
          path: 'docs/',
          isDirectory: true,
          children: [
            FileNode(
              name: 'design_docs',
              path: 'docs/design_docs/',
              isDirectory: true,
              children: [
                FileNode(
                  name: '00_milestone_summary.md',
                  path: 'docs/design_docs/00_milestone_summary.md',
                  type: 'doc',
                  size: '1.4 KB',
                  summary: 'Tracks project achievements, linter audits, and milestone records.',
                ),
              ],
            ),
            FileNode(
              name: 'knowledge_base',
              path: 'docs/knowledge_base/',
              isDirectory: true,
              children: [
                FileNode(
                  name: 'lessons_learned.md',
                  path: 'docs/knowledge_base/lessons_learned.md',
                  type: 'doc',
                  size: '1.6 KB',
                  summary: 'Summarizes technical bug fixes: HTTP overrides and sub-pixel RenderFlex overflow corrections.',
                ),
              ],
            ),
          ],
        ),
        FileNode(
          name: 'pubspec.yaml',
          path: 'pubspec.yaml',
          type: 'config',
          size: '4.1 KB',
          summary: 'Configures dependencies (provider, google_fonts, file_picker, http) and sets material-design true.',
        ),
        FileNode(
          name: 'README.md',
          path: 'README.md',
          type: 'doc',
          size: '4.8 KB',
          summary: 'Premium workspace handbook detailing visual themes, CLI codes, and setup procedures.',
        ),
      ],
    );
    _selectedFile = _rootNode.children.firstWhere((node) => node.name == 'pubspec.yaml');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace Explorer',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Inspect actual files, design documentation, and folder directories in this local project',
            style: TextStyle(fontSize: 14, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingExtraLarge),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Collapsible File Tree Panel
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.cardBg,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: AppConstants.cardStroke),
                    ),
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.folder_open, color: AppConstants.accent),
                            SizedBox(width: 8),
                            Text(
                              'Local Workspace Tree',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textPrimary),
                            ),
                          ],
                        ),
                        const Divider(color: AppConstants.cardStroke, height: 24),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildTreeNode(_rootNode, 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingLarge),

                // File Preview Panel
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.cardBg,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: AppConstants.cardStroke),
                    ),
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: _selectedFile == null
                        ? _buildNoSelectionState()
                        : _buildFilePreviewPanel(_selectedFile!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(FileNode node, int depth) {
    final hasChildren = node.isDirectory && node.children.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (node.isDirectory) {
                node.isExpanded = !node.isExpanded;
              } else {
                _selectedFile = node;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.only(
              left: depth * 16.0 + 8.0,
              top: 6.0,
              bottom: 6.0,
              right: 8.0,
            ),
            child: Row(
              children: [
                Icon(
                  node.isDirectory
                      ? (node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)
                      : Icons.insert_drive_file_outlined,
                  size: 16,
                  color: AppConstants.textMuted,
                ),
                const SizedBox(width: 6),
                Icon(
                  node.isDirectory
                      ? (node.isExpanded ? Icons.folder_open : Icons.folder)
                      : _getFileIcon(node.type),
                  size: 16,
                  color: _getFileColor(node),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: node.isDirectory ? FontWeight.bold : FontWeight.normal,
                      color: (_selectedFile == node) ? AppConstants.primary : AppConstants.textPrimary,
                    ),
                  ),
                ),
                if (!node.isDirectory)
                  Text(
                    node.size,
                    style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
                  ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded && hasChildren)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: node.children.map((child) => _buildTreeNode(child, depth + 1)).toList(),
          ),
      ],
    );
  }

  Widget _buildFilePreviewPanel(FileNode file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getFileIcon(file.type), color: _getFileColor(file), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.path,
                    style: const TextStyle(fontSize: 11, color: AppConstants.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: AppConstants.cardStroke, height: 32),
        const Text(
          'FILE SUMMARY & ARCHITECTURE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppConstants.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          file.summary,
          style: const TextStyle(fontSize: 14, color: AppConstants.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppConstants.paddingExtraLarge),
        const Text(
          'MOCK PREVIEW SOURCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppConstants.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.cardStroke),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                _getMockSourcePreview(file),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  color: Colors.greenAccent,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoSelectionState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.description_outlined, size: 64, color: AppConstants.textMuted),
          SizedBox(height: 16),
          Text(
            'No File Selected',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Select a code snippet, system design doc, or configuration file from the tree view to inspect.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'code':
        return Icons.code;
      case 'config':
        return Icons.settings;
      case 'doc':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(FileNode node) {
    if (node.isDirectory) return AppConstants.primary;
    switch (node.type) {
      case 'code':
        return AppConstants.accent;
      case 'config':
        return AppConstants.secondary;
      case 'doc':
        return Colors.greenAccent;
      default:
        return AppConstants.textMuted;
    }
  }

  String _getMockSourcePreview(FileNode file) {
    if (file.type == 'config') {
      if (file.name == 'pubspec.yaml') {
        return 'name: media_chronicle\n'
            'description: "A new Flutter project."\n'
            'publish_to: \'none\'\n'
            'version: 1.0.0+1\n\n'
            'environment:\n'
            '  sdk: ^3.11.5\n\n'
            'dependencies:\n'
            '  flutter:\n'
            '    sdk: flutter\n'
            '  cupertino_icons: ^1.0.8\n'
            '  provider: ^6.1.2\n'
            '  google_fonts: ^6.2.1\n'
            '  file_picker: ^8.1.3\n'
            '  image_picker: ^1.1.2\n'
            '  http: ^1.2.1';
      }
      return '/* Config Mock Source */\n{\n  "status": "active",\n  "workspace": "local_dev"\n}';
    } else if (file.type == 'doc') {
      return '# ${file.name}\n\n'
          'This is a visual preview of the project markdown file. The actual content is fully synchronized and committed inside the workspace directory.\n\n'
          '*   Milestone Status: Completed\n'
          '*   Audited: Yes\n'
          '*   Coverage: 100% compilation safety';
    } else {
      if (file.name == 'app_state.dart') {
        return 'import \'package:flutter/foundation.dart\';\n\n'
            'enum AppTab { stories, gallery, settings, explorer }\n\n'
            'class AppState extends ChangeNotifier {\n'
            '  AppTab _currentTab = AppTab.stories;\n'
            '  String _searchQuery = \'\';\n'
            '  String _activeGroupFilter = \'All\';\n'
            '  String? _activeTagFilter;\n'
            '  String? _activeAlbumId;\n\n'
            '  AppTab get currentTab => _currentTab;\n'
            '  String get searchQuery => _searchQuery;\n'
            '  String get activeGroupFilter => _activeGroupFilter;\n'
            '  String? get activeTagFilter => _activeTagFilter;\n'
            '  String? get activeAlbumId => _activeAlbumId;\n'
            '}';
      }
      return 'import \'package:flutter/material.dart\';\n'
          'import \'package:provider/provider.dart\';\n\n'
          '// Premium twilight codebase modules\n'
          'void main() {\n'
          '  debugPrint("Active local session verified.");\n'
          '}';
    }
  }
}
