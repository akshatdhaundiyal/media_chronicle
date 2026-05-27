import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/detected_face.dart';
import '../../providers/yolo_face_provider.dart';

/// A premium interactive dialog enabling users to label unidentified detected faces.
///
/// This form operates as a dual-step active-learning dialog:
/// 1. **Identity Enrollment**: The user inputs a text label representing the person.
/// 2. **Age Progression Drift Check**: If the provider detects that the facial embedding
///    varies significantly from prior images of the same name (low confidence matching),
///    the form triggers an inline secondary verification asking whether it is the "Same Person (Age Variant)"
///    or a "Different Person". This helps catalog physical age drift over time.
class FaceLabelingDialog extends StatefulWidget {
  /// The specific face region coordinate details being labeled.
  final DetectedFace face;

  /// The unique SHA-256 identifier of the parent image hosting this face.
  final String parentSha256;

  const FaceLabelingDialog({
    super.key,
    required this.face,
    required this.parentSha256,
  });

  @override
  State<FaceLabelingDialog> createState() => _FaceLabelingDialogState();

  /// Utility entrypoint to display the labeling form as a modal dialog layer.
  static void show(BuildContext context, DetectedFace face, String parentSha256) {
    showDialog(
      context: context,
      builder: (context) => FaceLabelingDialog(
        face: face,
        parentSha256: parentSha256,
      ),
    );
  }
}

class _FaceLabelingDialogState extends State<FaceLabelingDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.face.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yoloFaceProv = context.read<YoloFaceProvider>();

    return AlertDialog(
      backgroundColor: AppConstants.dialogBg,
      title: Row(
        children: const [
          Icon(Icons.face_unlock_outlined, color: AppConstants.accent),
          SizedBox(width: 8),
          Text('Identify Person'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the name of the person in this bounding box. The YOLO neural classifier will retrain itself to associate these facial features.',
            style: TextStyle(fontSize: 12.5, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Person Name',
              hintText: 'e.g. John, Sarah, Emma',
              labelStyle: const TextStyle(color: AppConstants.textSecondary),
              hintStyle: const TextStyle(color: AppConstants.textMuted),
              fillColor: AppConstants.inputBg,
              filled: true,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppConstants.cardStroke),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppConstants.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(context); // Close identity dialog

            // Check for age variant confirmation
            final shouldPromptVariant = yoloFaceProv.checkShouldPromptAgeVariant(widget.face.id, name);

            if (shouldPromptVariant) {
              // Trigger Age Variant Confirmation Dialog
              showDialog(
                context: context,
                builder: (variantCtx) => AlertDialog(
                  backgroundColor: AppConstants.dialogBg,
                  title: Row(
                    children: const [
                      Icon(Icons.history_toggle_off, color: AppConstants.secondary),
                      SizedBox(width: 8),
                      Text('Age Variant Detected'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We detected a significant variation in facial structure compared to existing photos of "$name".',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Since faces change naturally as one grows up and ages, is this the same person at a different age, or a different person entirely?',
                        style: TextStyle(fontSize: 12.5, color: AppConstants.textSecondary),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(variantCtx),
                      child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        yoloFaceProv.labelFace(widget.face.id, name, isAgeVariant: false, parentSha256: widget.parentSha256);
                        Navigator.pop(variantCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registered as different identity: $name (2)')),
                        );
                      },
                      child: const Text('Different Person', style: TextStyle(color: AppConstants.accent)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        yoloFaceProv.labelFace(widget.face.id, name, isAgeVariant: true, parentSha256: widget.parentSha256);
                        Navigator.pop(variantCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registered as new Age Variant for $name!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondary),
                      child: const Text('Same Person (Age Variant)', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else {
              yoloFaceProv.labelFace(widget.face.id, name, isAgeVariant: false, parentSha256: widget.parentSha256);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enrolled $name. Neural retraining initialized.')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accent),
          child: const Text('Identify & Train', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
