import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../ustaad_state.dart';
import '../widgets/common_widgets.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog(BuildContext context) {
    final state = context.read<UstaadState>();
    final keyCtrl = TextEditingController(text: state.aiRouter.apiKey);
    final geminiCtrl = TextEditingController(text: state.aiRouter.geminiApiKey);
    final modelCtrl = TextEditingController(text: state.aiRouter.model);
    final urlCtrl = TextEditingController(text: state.aiRouter.apiUrl);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('AI Engine Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ustaad operates on a resilient 3-tier architecture:\n'
                  '1. Cloud AI: OpenRouter (DeepSeek) or Google Gemini 1.5 Flash\n'
                  '2. On-Device AI: Llama (GGUF via llamadart)\n'
                  '3. Safety Net: On-Device Heuristic Engine',
                  style: TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Google Gemini API Key',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: geminiCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.auto_awesome),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'OpenRouter / DeepSeek API Key',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenRouter Key',
                    hintText: 'sk-or-v1-...',
                    prefixIcon: Icon(Icons.key),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'OpenRouter Model',
                    hintText: 'deepseek/deepseek-chat',
                    prefixIcon: Icon(Icons.psychology),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://openrouter.ai/api/v1',
                    prefixIcon: Icon(Icons.dns),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                state.setCloudApiKey('');
                state.aiRouter.setGeminiApiKey('');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Clear Keys'),
            ),
            FilledButton(
              onPressed: () {
                final geminiVal = geminiCtrl.text.trim();
                final openRouterVal = keyCtrl.text.trim();

                if (geminiVal.isNotEmpty) {
                  state.aiRouter.setGeminiApiKey(geminiVal);
                }
                if (openRouterVal.isNotEmpty) {
                  state.setSecondaryEngineConfig(
                    url: urlCtrl.text,
                    key: openRouterVal,
                    model: modelCtrl.text,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save Settings'),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    context.read<UstaadState>().sendChatMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final theme = Theme.of(context);
    final hasCloud = state.aiRouter.hasCloudKey;

    final ladderSubtitle = hasCloud
        ? 'Failover: OpenRouter (${state.aiRouter.model}) ➔ On-Device Llama ➔ Safety Net'
        : 'Safety Net: On-Device Heuristics';

    return Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
            title: 'Ustaad AI',
            subtitle: ladderSubtitle,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            actions: [
              IconButton(
                tooltip: 'AI Engine Ladder Settings',
                icon: Icon(
                  Icons.tune,
                  color: hasCloud
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _showApiKeyDialog(context),
              ),
              IconButton(
                tooltip: 'Clear Chat',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<UstaadState>().clearChat(),
              ),
            ],
            showNav: true,
          ),
          const SizedBox(height: 12),
          if (!hasCloud) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showApiKeyDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(55),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using On-Device Safety Net. Tap here to add an OpenRouter or Gemini API key for full AI reasoning.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.tune,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            height: 480,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = state.chatMessages[index];
                      return ChatMessageBubble(message: msg);
                    },
                  ),
                ),
                if (state.chatBusy) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ustaad AI is thinking...',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Type in English, Urdu, or Roman Urdu...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: state.chatBusy ? null : _sendMessage,
                        icon: const Icon(Icons.send, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final AIChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Icon(Icons.smart_toy,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
              ],
              Text(
                isUser ? 'You' : 'Ustaad AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(color: fg, fontSize: 13.5, height: 1.4),
                  ),
                  if (message.suggestedAction != null &&
                      message.suggestedRole != null) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        context.read<UstaadState>().startAnalysis(
                              '${message.suggestedRole} required',
                              context.read<UstaadState>().lastLocation,
                              initialOffer: message.suggestedBudget,
                            );
                      },
                      icon: const Icon(Icons.handyman, size: 16),
                      label: Text(message.suggestedAction!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
