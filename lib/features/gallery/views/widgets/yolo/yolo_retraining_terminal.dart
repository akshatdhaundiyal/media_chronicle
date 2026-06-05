import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../providers/yolo_face_provider.dart';

/// Renders a stateful retro terminal displaying dynamic neural retraining logs.
/// Isolates scroll controllers and frame paint routines from impacting parent containers.
class YoloRetrainingTerminal extends ConsumerStatefulWidget {
  const YoloRetrainingTerminal({super.key});

  @override
  ConsumerState<YoloRetrainingTerminal> createState() => _YoloRetrainingTerminalState();
}

class _YoloRetrainingTerminalState extends ConsumerState<YoloRetrainingTerminal> {
  /// Self-contained ScrollController to manage logs console scrolling.
  final ScrollController _terminalScrollController = ScrollController();

  /// Clean teardown of ScrollController listeners to prevent resource and memory leaks.
  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch training logs emitted by the active learning backpropagation provider.
    final yoloState = ref.watch(yoloFaceProvider);

    // Autoscroll training logs terminal on update.
    // We defer the jump to a post-frame callback to ensure that the layout is completely
    // painted with the new list items before querying the max scroll extent.
    if (yoloState.isTraining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_terminalScrollController.hasClients) {
          _terminalScrollController.jumpTo(_terminalScrollController.position.maxScrollExtent);
        }
      });
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.terminalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header scroller titles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.terminal_outlined, color: Colors.amberAccent, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Training Backpropagation Terminal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              // Activity loading indicator while SGD training is active
              if (yoloState.isTraining)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(Colors.amberAccent),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.white10),
          
          // Terminal console body displaying backpropagation iterations
          Expanded(
            child: ListView.builder(
              controller: _terminalScrollController,
              itemCount: yoloState.trainingLogs.length,
              itemBuilder: (context, index) {
                final log = yoloState.trainingLogs[index];
                
                // Color tokens dynamically based on log status matches
                Color textColor = AppConstants.textSecondary;
                if (log.contains('SUCCESS')) textColor = Colors.greenAccent;
                if (log.contains('completed') || log.contains('synced')) textColor = AppConstants.accent;
                if (log.contains('Epoch')) textColor = Colors.amberAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
