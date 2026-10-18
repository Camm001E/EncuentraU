import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/presentation/widgets/page_visibility.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage(
      {required this.conversationId,
      required this.createController,
      required this.releaseController,
      required this.observer,
      super.key});
  final String conversationId;
  final ChatController Function() createController;
  final ValueChanged<ChatController> releaseController;
  final RouteObserver<ModalRoute<dynamic>> observer;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController controller = widget.createController();
  final _body = TextEditingController();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.open(widget.conversationId);
    });
  }

  @override
  void dispose() {
    controller.setVisible(false);
    widget.releaseController(controller);
    _body.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final success = await controller.send(_body.text);
    if (!mounted || !success) return;
    _body.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Widget composer(bool compact) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.actionMessage != null) ...[
                  Text(controller.actionMessage!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSizes.spacingSmall)
                ],
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: TextField(
                          key: const Key('chat-message-input'),
                          controller: _body,
                          enabled: !controller.isSending &&
                              controller.conversation?.status ==
                                  ConversationStatus.active,
                          minLines: 1,
                          maxLines: compact
                              ? AppSizes.chatCompactInputLines
                              : AppSizes.chatInputMaxLines,
                          maxLength: ApiConstants.maximumMessageLength,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                              hintText: AppStrings.writeMessage,
                              labelText: AppStrings.writeMessage))),
                  const SizedBox(width: AppSizes.spacingSmall),
                  IconButton.filled(
                      key: const Key('send-chat-message'),
                      tooltip: controller.isSending
                          ? AppStrings.sendingMessage
                          : AppStrings.sendMessage,
                      onPressed: controller.isSending ||
                              controller.conversation?.status !=
                                  ConversationStatus.active
                          ? null
                          : send,
                      icon: controller.isSending
                          ? const SizedBox.square(
                              dimension: AppSizes.iconMedium,
                              child: CircularProgressIndicator(
                                  strokeWidth: AppSizes.strokeWidth))
                          : const Icon(Icons.send_rounded)),
                ])
              ])));
  Widget messages() {
    final items = controller.messages;
    if (items.isEmpty)
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(AppSizes.spacingLarge),
              child: Text(AppStrings.noMessages)));
    return ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        itemCount: items.length + (controller.nextCursor == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == items.length)
            return SecondaryAction(
                label: AppStrings.previousMessages,
                onPressed:
                    controller.isLoadingOlder ? null : controller.loadOlder);
          final message = items[items.length - 1 - index];
          return MessageBubble(
              key: ValueKey(message.id),
              message: message,
              otherName: controller.conversation!.otherDisplayName);
        });
  }

  @override
  Widget build(BuildContext context) => PageVisibility(
      observer: widget.observer,
      onChanged: controller.setVisible,
      child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final conversation = controller.conversation;
            return Scaffold(
                appBar: AppBar(
                    title: Text(conversation?.otherDisplayName ??
                        AppStrings.privateChat)),
                body: ContentWidth(
                    maxWidth: AppSizes.detailMaxWidth,
                    child: Builder(builder: (context) {
                      if (controller.status == LoadStatus.initial ||
                          controller.status == LoadStatus.loading)
                        return const Padding(
                            padding: EdgeInsets.all(AppSizes.spacingLarge),
                            child: LoadingSkeleton());
                      if (conversation == null)
                        return LoadFeedback(
                            message:
                                controller.message ?? AppStrings.apiNotFound,
                            onRetry: controller.refresh);
                      return LayoutBuilder(builder: (context, constraints) {
                        final compact =
                            constraints.maxHeight < AppSizes.chatCompactHeight;
                        if (constraints.maxHeight <
                            AppSizes.chatMinimumBodyHeight *
                                    MediaQuery.textScalerOf(context).scale(1) +
                                AppSizes.spacingLarge)
                          return SingleChildScrollView(child: composer(true));
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!compact)
                                Padding(
                                    padding: const EdgeInsets.all(
                                        AppSizes.spacingMedium),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                              width:
                                                  AppSizes.reportPhotoThumbnail,
                                              child: ReportPhoto(
                                                  thumbnail: true,
                                                  image:
                                                      conversation.report.image,
                                                  height: AppSizes
                                                      .reportPhotoThumbnail)),
                                          const SizedBox(
                                              width: AppSizes.spacingMedium),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(
                                                    conversation
                                                        .report.objectType,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),
                                                const SizedBox(
                                                    height:
                                                        AppSizes.spacingSmall),
                                                StatusPill(
                                                    label:
                                                        AppStrings.approvedChat,
                                                    icon: Icons.shield_outlined,
                                                    tone: AppSemanticColors.of(
                                                            context)
                                                        .success),
                                              ]))
                                        ])),
                              if (controller.message != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.spacingMedium),
                                    child: Row(children: [
                                      Expanded(
                                          child: Text(controller.message!)),
                                      IconButton(
                                          tooltip: AppStrings.retry,
                                          onPressed: controller.refresh,
                                          icon:
                                              const Icon(Icons.refresh_rounded))
                                    ])),
                              Expanded(child: messages()),
                              const Divider(height: 1),
                              composer(compact),
                            ]);
                      });
                    })));
          }));
}
