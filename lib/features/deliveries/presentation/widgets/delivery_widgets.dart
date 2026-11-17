import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/app_motion.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/delivery.dart';
import '../controllers/delivery_controller.dart';
import 'delivery_scope.dart';

extension DeliveryLabel on DeliveryStatus {
  String get label => switch (this) {
        DeliveryStatus.coordinating => AppStrings.coordinatingDelivery,
        DeliveryStatus.awaitingConfirmations =>
          AppStrings.awaitingConfirmations,
        DeliveryStatus.awaitingAdmin => AppStrings.awaitingAdmin,
        DeliveryStatus.disputed => AppStrings.deliveryDisputed,
        DeliveryStatus.completed => AppStrings.deliveryCompleted,
      };
}

SemanticTone deliveryTone(BuildContext context, DeliveryStatus status) =>
    switch (status) {
      DeliveryStatus.completed => AppSemanticColors.of(context).success,
      DeliveryStatus.disputed => AppSemanticColors.of(context).warning,
      _ => AppSemanticColors.of(context).information,
    };
IconData deliveryIcon(DeliveryStatus status) => switch (status) {
      DeliveryStatus.completed => Icons.task_alt_rounded,
      DeliveryStatus.disputed => Icons.report_problem_outlined,
      DeliveryStatus.awaitingAdmin => Icons.fact_check_outlined,
      _ => Icons.handshake_outlined,
    };

class DeliveryStatusPill extends StatelessWidget {
  const DeliveryStatusPill(this.status, {super.key});
  final DeliveryStatus status;
  @override
  Widget build(BuildContext context) => StatusPill(
      label: status.label,
      icon: deliveryIcon(status),
      tone: deliveryTone(context, status));
}

class DeliveryTimeline extends StatelessWidget {
  const DeliveryTimeline(this.delivery, {super.key});
  final DeliveryRecord delivery;
  @override
  Widget build(BuildContext context) {
    final both = delivery.claimantConfirmedAt != null &&
        delivery.custodianConfirmedAt != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final step in [
        (AppStrings.claimApproved, true),
        (AppStrings.coordinatingDelivery, true),
        (AppStrings.custodianConfirmed, delivery.custodianConfirmedAt != null),
        (AppStrings.claimantConfirmed, delivery.claimantConfirmedAt != null),
        (AppStrings.awaitingAdmin, both),
        (
          AppStrings.deliveryCompleted,
          delivery.status == DeliveryStatus.completed
        ),
      ])
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppSizes.spacingSmall),
            child: Semantics(
                label: step.$1,
                checked: step.$2,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                          child: Icon(
                              step.$2
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: step.$2
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                      const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(child: Text(step.$1)),
                    ]))),
    ]);
  }
}

String eventLabel(DeliveryEventType type) => switch (type) {
      DeliveryEventType.deliveryCreated => AppStrings.deliveryCreated,
      DeliveryEventType.custodianConfirmed => AppStrings.custodianConfirmed,
      DeliveryEventType.claimantConfirmed => AppStrings.claimantConfirmed,
      DeliveryEventType.disputeOpened => AppStrings.deliveryDisputed,
      DeliveryEventType.adminReopened => AppStrings.deliveryReopened,
      DeliveryEventType.adminCompleted => AppStrings.deliveryAdminCompleted,
    };

class DeliveryHistory extends StatelessWidget {
  const DeliveryHistory(this.events, {super.key});
  final List<DeliveryEvent> events;
  @override
  Widget build(BuildContext context) =>
      ExpansionTile(title: const Text(AppStrings.deliveryHistory), children: [
        for (final event in events)
          Padding(
              padding: const EdgeInsets.all(AppSizes.spacingMedium),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eventLabel(event.type),
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(AppStrings.deliveryEventWhen(
                            formatDate(event.createdAt.toLocal()),
                            MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(
                                    event.createdAt.toLocal())))),
                        if (event.note != null) Text(event.note!),
                      ]))),
      ]);
}

enum DeliveryDecision { confirm, dispute, complete, reopen }

class DeliveryDecisionDialog extends StatefulWidget {
  const DeliveryDecisionDialog(this.decision, {super.key});
  final DeliveryDecision decision;
  @override
  State<DeliveryDecisionDialog> createState() => _DeliveryDecisionDialogState();
}

class _DeliveryDecisionDialogState extends State<DeliveryDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.decision;
    final title = switch (d) {
      DeliveryDecision.confirm => AppStrings.confirm,
      DeliveryDecision.dispute => AppStrings.reportDeliveryProblem,
      DeliveryDecision.complete => AppStrings.completeDelivery,
      DeliveryDecision.reopen => AppStrings.reopenDelivery
    };
    final help = switch (d) {
      DeliveryDecision.confirm => AppStrings.confirmPhysicalDelivery,
      DeliveryDecision.dispute => AppStrings.disputeHelp,
      DeliveryDecision.complete => AppStrings.completeDeliveryHelp,
      DeliveryDecision.reopen => AppStrings.reopenDeliveryHelp
    };
    return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
            child: Form(
                key: _form,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(help),
                      if (d != DeliveryDecision.confirm) ...[
                        const SizedBox(height: AppSizes.spacingLarge),
                        TextFormField(
                            controller: _text,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: DeliveryLimits.maximumNoteLength,
                            decoration: InputDecoration(
                                labelText: d == DeliveryDecision.dispute
                                    ? AppStrings.disputeReason
                                    : AppStrings.deliveryAdminNote,
                                helperText: d == DeliveryDecision.dispute
                                    ? null
                                    : AppStrings.deliveryNoteHelp,
                                helperMaxLines: 3),
                            validator: (value) {
                              final n = (value ?? '').trim().runes.length;
                              if (d == DeliveryDecision.dispute &&
                                  n < DeliveryLimits.minimumReasonLength)
                                return AppStrings.disputeValidation;
                              if (d == DeliveryDecision.reopen && n == 0)
                                return AppStrings.deliveryNoteValidation;
                              if (n > DeliveryLimits.maximumNoteLength)
                                return AppStrings.deliveryNoteValidation;
                              return null;
                            }),
                      ]
                    ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.dismiss)),
          FilledButton(
              onPressed: () {
                if (_form.currentState!.validate())
                  Navigator.pop(context, _text.text.trim());
              },
              child: Text(title)),
        ]);
  }
}

Future<void> deliveryDecision(BuildContext context,
    DeliveryController controller, DeliveryDecision decision) async {
  final note = await showDialog<String>(
      context: context, builder: (_) => DeliveryDecisionDialog(decision));
  if (note == null || !context.mounted) return;
  final success = await switch (decision) {
    DeliveryDecision.confirm => controller.confirm(),
    DeliveryDecision.dispute => controller.dispute(note),
    DeliveryDecision.complete =>
      controller.complete(note: note.isEmpty ? null : note),
    DeliveryDecision.reopen => controller.reopen(note),
  };
  if (context.mounted && !success)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(controller.actionMessage ?? AppStrings.unexpectedError)));
}

class DeliveryContent extends StatelessWidget {
  const DeliveryContent(
      {required this.delivery, required this.controller, super.key});
  final DeliveryRecord delivery;
  final DeliveryController controller;
  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final done = d.status == DeliveryStatus.completed;
    final events = d is Delivery ? d.events : (d as AdminDelivery).events;
    final reason =
        d is Delivery ? d.disputeReason : (d as AdminDelivery).disputeReason;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
          alignment: Alignment.centerLeft, child: DeliveryStatusPill(d.status)),
      const SizedBox(height: AppSizes.spacingMedium),
      AnimatedSwitcher(
          duration: AppMotion.duration(context, AppDurations.micro),
          child: done
              ? InformationPanel(
                  key: ValueKey(d.status),
                  tone: AppSemanticColors.of(context).success,
                  icon: Icons.task_alt_rounded,
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.deliveryClosedMessage),
                        Text(AppStrings.deliveryClosedHelp)
                      ]))
              : const SizedBox.shrink()),
      DeliveryTimeline(d),
      if (reason != null)
        InformationPanel(
            tone: AppSemanticColors.of(context).warning,
            icon: Icons.report_problem_outlined,
            child: Text(reason)),
      if (d is Delivery) ...[
        if (d.myConfirmedAt != null)
          const Text(AppStrings.myDeliveryConfirmation),
        Text(d.otherConfirmedAt != null
            ? AppStrings.otherDeliveryConfirmation
            : AppStrings.waitingOtherConfirmation),
        if (d.canConfirm)
          Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSizes.spacingMedium),
              child: PrimaryAction(
                  label: d.relationship == DeliveryRole.custodian
                      ? AppStrings.confirmCustodianDelivery
                      : AppStrings.confirmClaimantDelivery,
                  busy: controller.isActing,
                  onPressed: controller.isActing
                      ? null
                      : () => deliveryDecision(
                          context, controller, DeliveryDecision.confirm))),
        if (d.canDispute)
          SecondaryAction(
              label: AppStrings.reportDeliveryProblem,
              icon: Icons.report_problem_outlined,
              onPressed: controller.isActing
                  ? null
                  : () => deliveryDecision(
                      context, controller, DeliveryDecision.dispute)),
      ],
      if (d is AdminDelivery) ...[
        const SizedBox(height: AppSizes.spacingMedium),
        const InformationPanel(
            icon: Icons.lock_outline, child: Text(AppStrings.chatMetadataOnly)),
        if (d.messageCount != null)
          Text(AppStrings.deliveryMessageCount(d.messageCount!)),
        if (d.lastActivityAt != null)
          Text(formatDate(d.lastActivityAt!.toLocal())),
        if (d.adminNote != null)
          Text('${AppStrings.deliveryAdminNote}: ${d.adminNote}'),
        const SizedBox(height: AppSizes.spacingMedium),
        PrimaryAction(
            label: AppStrings.completeDelivery,
            busy: controller.isActing,
            onPressed:
                controller.isActing || d.status != DeliveryStatus.awaitingAdmin
                    ? null
                    : () => deliveryDecision(
                        context, controller, DeliveryDecision.complete)),
        const SizedBox(height: AppSizes.spacingMedium),
        SecondaryAction(
            label: AppStrings.reopenDelivery,
            onPressed: controller.isActing ||
                    !{DeliveryStatus.disputed, DeliveryStatus.awaitingAdmin}
                        .contains(d.status)
                ? null
                : () => deliveryDecision(
                    context, controller, DeliveryDecision.reopen)),
      ],
      if (controller.actionMessage != null) Text(controller.actionMessage!),
      const SizedBox(height: AppSizes.spacingMedium),
      DeliveryHistory(events),
    ]);
  }
}

class DeliveryProgressLink extends StatefulWidget {
  const DeliveryProgressLink(
      {required this.conversationId, this.inChat = false, super.key});
  final String conversationId;
  final bool inChat;
  @override
  State<DeliveryProgressLink> createState() => _DeliveryProgressLinkState();
}

class _DeliveryProgressLinkState extends State<DeliveryProgressLink> {
  DeliveryController? _controller;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DeliveryScope.maybeOf(context)?.student;
    if (c != _controller) {
      _controller = c;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c?.loadDetail(widget.conversationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final d = c.detail;
          final content = d is Delivery &&
                  d.conversationId == widget.conversationId
              ? DeliveryContent(delivery: d, controller: c)
              : c.detailStatus == LoadStatus.error
                  ? LoadFeedback(
                      message: c.detailMessage ?? AppStrings.unexpectedError,
                      onRetry: () => c.loadDetail(widget.conversationId))
                  : const LoadingSkeleton(count: 1);
          if (widget.inChat)
            return ExpansionTile(
                key: const Key('chat-delivery-panel'),
                title: const Text(AppStrings.deliveryProcess),
                subtitle: d?.conversationId == widget.conversationId
                    ? Text(d!.status.label)
                    : null,
                children: [
                  ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxHeight: AppSizes.deliveryPanelMaxHeight),
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSizes.spacingMedium),
                          child: content)),
                  TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.deliveryDetail,
                          arguments: widget.conversationId),
                      child: const Text(AppStrings.deliveryDetails))
                ]);
          return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.handshake_outlined),
              title: const Text(AppStrings.deliveryProcess),
              subtitle: d?.conversationId == widget.conversationId
                  ? Text(d!.status.label)
                  : null,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.deliveryDetail,
                  arguments: widget.conversationId));
        });
  }
}

class DeliveryTotals extends StatefulWidget {
  const DeliveryTotals({this.admin = false, this.onStatus, super.key});
  final bool admin;
  final ValueChanged<DeliveryStatus>? onStatus;
  @override
  State<DeliveryTotals> createState() => _DeliveryTotalsState();
}

class _DeliveryTotalsState extends State<DeliveryTotals> {
  DeliveryController? _controller;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DeliveryScope.maybeOf(context);
    final c = widget.admin ? scope?.admin : scope?.student;
    if (c != _controller) {
      _controller = c;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c?.refreshCounts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          if (c.countsStatus == LoadStatus.error)
            return LoadFeedback(
                message: c.countsMessage ?? AppStrings.unexpectedError,
                onRetry: c.refreshCounts);
          final totals = c.totals;
          if (totals == null) return const LoadingSkeleton(count: 1);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeading(title: AppStrings.deliveryProcess),
                if (widget.admin)
                  for (final s in DeliveryStatus.values)
                    Card(
                        child: ListTile(
                            leading: Icon(deliveryIcon(s)),
                            title: Text(s.label),
                            subtitle: Text('${totals[s]}'),
                            onTap: widget.onStatus == null
                                ? null
                                : () => widget.onStatus!(s)))
                else ...[
                  Text(AppStrings.deliveryMetric(
                      AppStrings.deliveryCasesInProgress,
                      totals.entries
                          .where((e) => e.key != DeliveryStatus.completed)
                          .fold(0, (sum, e) => sum + e.value))),
                  Text(AppStrings.deliveryMetric(
                      AppStrings.deliveryCasesCompleted,
                      totals[DeliveryStatus.completed]!)),
                  TextButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.deliveries),
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text(AppStrings.myDeliveries)),
                ],
              ]);
        });
  }
}
