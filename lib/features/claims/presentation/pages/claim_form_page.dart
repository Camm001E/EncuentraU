import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../domain/entities/ownership_claim.dart';
import '../controllers/claims_controller.dart';

class ClaimFormPage extends StatefulWidget {
  const ClaimFormPage(
      {required this.matchId, required this.controller, super.key});
  final String matchId;
  final ClaimsController controller;
  @override
  State<ClaimFormPage> createState() => _ClaimFormPageState();
}

class _ClaimFormPageState extends State<ClaimFormPage> {
  final _form = GlobalKey<FormState>();
  final _evidence = TextEditingController();
  @override
  void dispose() {
    _evidence.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (widget.controller.isSubmitting || !_form.currentState!.validate())
      return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text(AppStrings.submitClaim),
                content: const Text(AppStrings.submitClaimConfirmation),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(AppStrings.workflowCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(AppStrings.confirm)),
                ]));
    if (!mounted || confirmed != true) return;
    final claim = await widget.controller
        .submit(widget.matchId, ClaimDraft(_evidence.text));
    if (!mounted || claim == null) return;
    Navigator.pushReplacementNamed(context, AppRoutes.claimDetail,
        arguments: claim.id);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return PopScope(
            canPop: !controller.isSubmitting,
            child: Scaffold(
                appBar: AppBar(title: const Text(AppStrings.claimThisObject)),
                body: ContentWidth(
                    maxWidth: AppSizes.objectFormMaxWidth,
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        child: Form(
                            key: _form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SectionHeading(
                                      title: AppStrings.claimFormTitle,
                                      subtitle: AppStrings.claimFormHelp),
                                  const InformationPanel(
                                      icon: Icons.shield_outlined,
                                      child: Text(
                                          AppStrings.sensitiveDataWarning)),
                                  const SizedBox(height: AppSizes.spacingLarge),
                                  TextFormField(
                                      key: const Key('ownership-evidence'),
                                      controller: _evidence,
                                      enabled: !controller.isSubmitting,
                                      minLines: AppSizes.evidenceInputMinLines,
                                      maxLines: AppSizes.evidenceInputMaxLines,
                                      maxLength:
                                          ApiConstants.maximumEvidenceLength,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: const InputDecoration(
                                          labelText:
                                              AppStrings.ownershipEvidenceLabel,
                                          helperText:
                                              AppStrings.ownershipEvidenceHelp,
                                          helperMaxLines:
                                              AppSizes.chatInputMaxLines),
                                      validator: (value) =>
                                          ClaimDraft(value ?? '').isValid
                                              ? null
                                              : AppStrings.evidenceValidation),
                                  if (controller.actionMessage != null) ...[
                                    const SizedBox(
                                        height: AppSizes.spacingMedium),
                                    InformationPanel(
                                        icon: Icons.info_outline,
                                        child: Text(controller.actionMessage!))
                                  ],
                                  const SizedBox(height: AppSizes.spacingLarge),
                                  PrimaryAction(
                                      label: AppStrings.submitClaim,
                                      onPressed: submit,
                                      busy: controller.isSubmitting,
                                      icon: Icons.fact_check_outlined),
                                ]))))));
      });
}
