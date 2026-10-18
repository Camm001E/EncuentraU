import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/presentation/widgets/page_visibility.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../controllers/conversations_controller.dart';
import '../widgets/message_bubble.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage(
      {required this.controller, required this.observer, super.key});
  final ConversationsController controller;
  final RouteObserver<ModalRoute<dynamic>> observer;
  @override
  Widget build(BuildContext context) => PageVisibility(
      observer: observer,
      onChanged: (visible) {
        if (visible) controller.refresh();
      },
      child: Scaffold(
          appBar: AppBar(title: const Text(AppStrings.messages)),
          body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final c = controller;
                return ContentWidth(
                    child: RefreshIndicator(
                        onRefresh: c.refresh,
                        child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.all(AppSizes.spacingLarge),
                            children: [
                              const SectionHeading(
                                  title: AppStrings.conversationsTitle,
                                  subtitle: AppStrings.conversationsHelp),
                              if (c.status == LoadStatus.initial ||
                                  c.status == LoadStatus.loading)
                                const LoadingSkeleton(),
                              if (c.status == LoadStatus.error)
                                LoadFeedback(
                                    message:
                                        c.message ?? AppStrings.unexpectedError,
                                    onRetry: c.refresh),
                              if (c.status == LoadStatus.empty)
                                const LoadFeedback(
                                    message: AppStrings.noConversations),
                              for (final conversation in c.items)
                                Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSizes.spacingMedium),
                                    child: Card(
                                        child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.radiusLarge),
                                            onTap: () => Navigator.pushNamed(
                                                context, AppRoutes.conversation,
                                                arguments: conversation.id),
                                            child: Padding(
                                                padding: const EdgeInsets.all(
                                                    AppSizes.spacingMedium),
                                                child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                          width: AppSizes
                                                              .reportPhotoThumbnail,
                                                          child: ReportPhoto(
                                                              thumbnail: true,
                                                              image:
                                                                  conversation
                                                                      .report
                                                                      .image,
                                                              height: AppSizes
                                                                  .reportPhotoThumbnail)),
                                                      const SizedBox(
                                                          width: AppSizes
                                                              .spacingMedium),
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                            Text(
                                                                conversation
                                                                    .otherDisplayName,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .titleMedium),
                                                            Text(conversation
                                                                .report
                                                                .objectType),
                                                            const SizedBox(
                                                                height: AppSizes
                                                                    .spacingSmall),
                                                            Text(
                                                                conversation
                                                                        .lastMessage
                                                                        ?.body ??
                                                                    AppStrings
                                                                        .noLastMessage,
                                                                maxLines: AppSizes
                                                                    .chatCompactInputLines,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis),
                                                            if (conversation
                                                                    .lastMessageAt !=
                                                                null)
                                                              Text(
                                                                  messageTime(
                                                                      conversation
                                                                          .lastMessageAt!),
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelMedium),
                                                            if (conversation
                                                                    .unreadCount >
                                                                0) ...[
                                                              const SizedBox(
                                                                  height: AppSizes
                                                                      .spacingSmall),
                                                              StatusPill(
                                                                  label: AppStrings
                                                                      .unreadMessages(
                                                                          conversation
                                                                              .unreadCount),
                                                                  icon: Icons
                                                                      .mark_chat_unread_outlined,
                                                                  tone: AppSemanticColors.of(
                                                                          context)
                                                                      .success)
                                                            ],
                                                          ]))
                                                    ]))))),
                              if (c.hasMore)
                                SecondaryAction(
                                    label: AppStrings.loadMore,
                                    onPressed:
                                        c.isLoadingMore ? null : c.loadMore),
                            ])));
              })));
}
