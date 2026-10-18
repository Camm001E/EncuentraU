import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class ReviewDecision {
  const ReviewDecision({this.note, this.reason});
  final String? note, reason;
}

class ReviewDecisionDialog extends StatefulWidget {
  const ReviewDecisionDialog({required this.approve, super.key});
  final bool approve;
  @override
  State<ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<ReviewDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController(), _reason = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.approve
              ? AppStrings.approveClaim
              : AppStrings.rejectClaim),
          content: SingleChildScrollView(
              child: Form(
                  key: _form,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.approve
                            ? AppStrings.approveClaimConfirmation
                            : AppStrings.rejectClaimConfirmation),
                        const SizedBox(height: AppSizes.spacingLarge),
                        if (!widget.approve) ...[
                          TextFormField(
                              key: const Key('rejection-reason'),
                              controller: _reason,
                              minLines: AppSizes.evidenceInputMinLines,
                              maxLines: AppSizes.evidenceInputMaxLines,
                              maxLength: ApiConstants.maximumNoteLength,
                              decoration: const InputDecoration(
                                  labelText: AppStrings.rejectionReasonLabel),
                              validator: (value) =>
                                  (value ?? '').trim().runes.length <
                                          ApiConstants.minimumRejectionLength
                                      ? AppStrings.reviewReasonValidation
                                      : null),
                          const SizedBox(height: AppSizes.spacingMedium)
                        ],
                        TextFormField(
                            key: const Key('admin-note'),
                            controller: _note,
                            minLines: 1,
                            maxLines: AppSizes.chatInputMaxLines,
                            maxLength: ApiConstants.maximumNoteLength,
                            decoration: const InputDecoration(
                                labelText: AppStrings.adminNote),
                            validator: (v) => (v ?? '').runes.length >
                                    ApiConstants.maximumNoteLength
                                ? AppStrings.noteValidation
                                : null),
                        const SizedBox(height: AppSizes.spacingSmall),
                        const Text(AppStrings.internalNoteHelp),
                      ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.workflowCancel)),
            FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  Navigator.pop(
                      context,
                      ReviewDecision(
                          note: _note.text.trim().isEmpty
                              ? null
                              : _note.text.trim(),
                          reason: widget.approve ? null : _reason.text.trim()));
                },
                child: const Text(AppStrings.confirm))
          ]);
}
