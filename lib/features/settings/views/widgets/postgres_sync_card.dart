import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/postgres_sync_service.dart';
import '../../providers/settings_provider.dart';

/// Renders the PostgreSQL database sync dashboard.
/// Encapsulates connection credential editing, migration DDL copies,
/// and retro SQL execution scroller consoles.
class PostgresSyncCard extends ConsumerStatefulWidget {
  const PostgresSyncCard({super.key});

  @override
  ConsumerState<PostgresSyncCard> createState() => _PostgresSyncCardState();
}

class _PostgresSyncCardState extends ConsumerState<PostgresSyncCard> {
  // Stateful controllers to prevent focus jumps and cursor resets on state updates.
  late final ScrollController _terminalController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _dbController;
  late final TextEditingController _userController;
  late final TextEditingController _passController;
  
  /// Toggles visibility of the expanded credentials parameters panel
  bool _isExpanded = false;

  /// Instantiate controllers synchronously in the widget initialization phase.
  @override
  void initState() {
    super.initState();
    _terminalController = ScrollController();
    final settings = ref.read(settingsProvider);
    _hostController = TextEditingController(text: settings.postgresHost);
    _portController = TextEditingController(text: settings.postgresPort.toString());
    _dbController = TextEditingController(text: settings.postgresDatabase);
    _userController = TextEditingController(text: settings.postgresUser);
    _passController = TextEditingController(text: settings.postgresPassword);
  }

  /// Clean, leak-free disposal of all controllers in the widget teardown phase.
  @override
  void dispose() {
    _terminalController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _dbController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch database connection statuses and configurations providers.
    final pgSyncState = ref.watch(postgresSyncProvider);
    final pgSyncNotifier = ref.read(postgresSyncProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Autoscroll db terminal to bottom dynamically after widget frame lays out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalController.hasClients) {
        _terminalController.jumpTo(_terminalController.position.maxScrollExtent);
      }
    });

    // Safely sync controller text fields if changed externally (e.g. dynamic settings resets)
    // without triggering cursor jump focus loops.
    if (_hostController.text != settings.postgresHost) {
      _hostController.text = settings.postgresHost;
    }
    if (_portController.text != settings.postgresPort.toString()) {
      _portController.text = settings.postgresPort.toString();
    }
    if (_dbController.text != settings.postgresDatabase) {
      _dbController.text = settings.postgresDatabase;
    }
    if (_userController.text != settings.postgresUser) {
      _userController.text = settings.postgresUser;
    }
    if (_passController.text != settings.postgresPassword) {
      _passController.text = settings.postgresPassword;
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
          // Header titles and Sync status indicators
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
                  color: pgSyncState.isConnected
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: pgSyncState.isConnected ? Colors.greenAccent : Colors.redAccent,
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
                        color: pgSyncState.isConnected ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pgSyncState.isConnected ? 'SYNC ACTIVE' : 'SYNC PAUSED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: pgSyncState.isConnected ? Colors.greenAccent : Colors.redAccent,
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
          
          // Main Switch Toggle and SQL Schema exporter DDL
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Postgres Sync Pipeline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${settings.postgresHost}:${settings.postgresPort}/${settings.postgresDatabase}', 
                    style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                  ),
                  value: pgSyncState.isConnected,
                  activeThumbColor: AppConstants.accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val) {
                      // Attempt dynamic native database connection asynchronously
                      pgSyncNotifier.toggleConnection(
                        true,
                        host: settings.postgresHost,
                        port: settings.postgresPort,
                        db: settings.postgresDatabase,
                        user: settings.postgresUser,
                        pass: settings.postgresPassword,
                        ssl: settings.postgresSsl,
                      ).then((_) {
                        if (pgSyncState.isConnected) {
                          pgSyncNotifier.processSyncQueue();
                        }
                      });
                    } else {
                      pgSyncNotifier.toggleConnection(false);
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Bind DDL migration queries directly to system clipboard
                  Clipboard.setData(ClipboardData(text: pgSyncNotifier.sqlSchemaMigration));
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
          
          // Expandable credential settings panels toggle
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppConstants.accent,
            ),
            label: Text(
              _isExpanded ? 'Hide Connection Credentials' : 'Configure Server Credentials & SSL',
              style: const TextStyle(fontSize: 11, color: AppConstants.accent),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.cardStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Postgres Server Target Configuration',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Host and Port input forms
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _hostController,
                          decoration: const InputDecoration(
                            labelText: 'Host IP/DNS',
                            hintText: 'e.g. localhost',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '5432',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // DB name and Username inputs
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dbController,
                          decoration: const InputDecoration(
                            labelText: 'Database Name',
                            hintText: 'e.g. chronicle',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'postgres',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Password and SSL Toggles
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'password',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('SSL Required', style: TextStyle(fontSize: 11)),
                          value: settings.postgresSsl,
                          activeThumbColor: AppConstants.accent,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => ref.read(settingsProvider.notifier).togglePostgresSsl(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Form submission apply and connect button
                      ElevatedButton.icon(
                        onPressed: () async {
                          final host = _hostController.text.trim();
                          final port = int.tryParse(_portController.text.trim()) ?? 5432;
                          final db = _dbController.text.trim();
                          final user = _userController.text.trim();
                          final pass = _passController.text;

                          // Cache configuration variables permanently
                          final settingsNotifier = ref.read(settingsProvider.notifier);
                          settingsNotifier.updatePostgresHost(host);
                          settingsNotifier.updatePostgresPort(port);
                          settingsNotifier.updatePostgresDatabase(db);
                          settingsNotifier.updatePostgresUser(user);
                          settingsNotifier.updatePostgresPassword(pass);
                          // Trigger socket initialization
                          await pgSyncNotifier.toggleConnection(
                            true,
                            host: host,
                            port: port,
                            db: db,
                            user: user,
                            pass: pass,
                            ssl: settings.postgresSsl,
                          );
 
                          // Instantly execute queued elements if connection successfully established
                          if (pgSyncState.isConnected) {
                            pgSyncNotifier.processSyncQueue();
                          }
                        },
                        icon: const Icon(Icons.sync_alt, size: 14),
                        label: const Text('Apply & Connect', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const Divider(),
          const SizedBox(height: 8),
          
          // Relational Database Sync statistics indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSyncStat('Database Transactions', '${pgSyncState.syncedRecords} rows synced'),
              _buildSyncStat('Offline Queue Buffer', '${pgSyncState.syncQueue.length} statements'),
            ],
          ),
          const SizedBox(height: 16),

          // Live terminal displaying background transactional logs scroller
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
                      onPressed: () => pgSyncNotifier.clearLogs(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView.builder(
                    controller: _terminalController,
                    itemCount: pgSyncState.syncLogs.length,
                    itemBuilder: (context, index) {
                      final log = pgSyncState.syncLogs[index];
                      
                      // Highlight tokens based on SQL transaction logs
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

  /// Helper card widget rendering title and statistics key-value layouts
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
