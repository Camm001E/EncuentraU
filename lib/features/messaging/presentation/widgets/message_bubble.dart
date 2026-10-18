import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/conversation.dart';

String messageTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {required this.message, required this.otherName, super.key});
  final ChatMessage message;
  final String otherName;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final author = message.isMine ? AppStrings.yourMessage : otherName,
        time = messageTime(message.createdAt);
    return Align(
        alignment:
            message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
            widthFactor: AppSizes.chatBubbleFraction,
            alignment:
                message.isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSizes.chatBubbleMaxWidth),
                child: Semantics(
                    label:
                        AppStrings.messageSemantics(author, time, message.body),
                    child: ExcludeSemantics(
                        child: Container(
                            margin: const EdgeInsets.only(
                                bottom: AppSizes.spacingMedium),
                            padding:
                                const EdgeInsets.all(AppSizes.spacingMedium),
                            decoration: BoxDecoration(
                                color: message.isMine
                                    ? scheme.primaryContainer
                                    : scheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusLarge)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(author,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  const SizedBox(height: AppSizes.spacingSmall),
                                  SelectableText(message.body),
                                  const SizedBox(height: AppSizes.spacingSmall),
                                  Text(time,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium),
                                ])))))));
  }
}
