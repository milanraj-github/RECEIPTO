import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/features/ai_assistant/domain/models/chat_message_model.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';
import 'package:receipto/features/ai_assistant/data/services/ai_assistant_service.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_product_card.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_receipt_card.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_warranty_card.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_summary_card.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_category_breakdown_card.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/ai_follow_up_chips.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestions = [
    'Show products above ₹2,000',
    'Which is my most expensive product?',
    'Show products under warranty',
    'Show receipts from this month',
    'Show category breakdown',
    'Show repeat purchases',
  ];

  @override
  void initState() {
    super.initState();
    // Default greeting with product awareness intro
    _messages.add(
      ChatMessage(
        text: "Hello! I am your **Receipto AI Agent**.\n\nI can analyze your **individual products**, line items, complete receipts, warranties, spending categories, and purchase history.\n\nTry asking:\n* *\"Show products above ₹2,000\"*\n* *\"What is my most expensive product?\"*\n* *\"Find electronics products under warranty\"*",
        isUser: false,
        timestamp: DateTime.now(),
        structuredResponse: const AIStructuredResponse(
          text: "",
          suggestedFollowUps: [
            'Show products above ₹2,000',
            'Which is my most expensive product?',
            'Show products under warranty',
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final service = ref.read(aiAssistantServiceProvider);
      final response = await service.askStructured(text);

      setState(() {
        _messages.add(ChatMessage(
          text: response.text,
          isUser: false,
          timestamp: DateTime.now(),
          structuredResponse: response,
        ));
        _isLoading = false;
      });

      // Handle direct navigation action if user explicitly requested opening a receipt
      if (response.action != null &&
          response.action!.actionType == 'openReceipt' &&
          response.action!.targetReceiptId != null &&
          mounted) {
        final targetId = response.action!.targetReceiptId!;
        context.push('/receipts/details/$targetId');
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an issue retrieving your records. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipto AI Agent',
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF66F2C1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Product & Receipt Intelligence',
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Conversation',
            icon: const Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: () {
              ref.read(aiAssistantServiceProvider).resetContext();
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: "Conversation context cleared. How can I help you today?",
                    isUser: false,
                    timestamp: DateTime.now(),
                    structuredResponse: const AIStructuredResponse(
                      text: "",
                      suggestedFollowUps: [
                        'Show products above ₹2,000',
                        'Which is my most expensive product?',
                        'Show products under warranty',
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Nebula Background
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.8),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg, textTheme);
                    },
                  ),
                ),

                if (_isLoading) _buildTypingIndicator(),

                // Suggestions if conversation is short
                if (_messages.length <= 2 && !_isLoading) _buildSuggestions(),

                _buildInputBar(textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, TextTheme textTheme) {
    final isUser = msg.isUser;
    final structured = msg.structuredResponse;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Text bubble
                  if (msg.text.trim().isNotEmpty)
                    GlassCard(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      backgroundColor: isUser
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.cardSurface.withValues(alpha: 0.5),
                      child: MarkdownText(
                        text: msg.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),

                  // Structured UI Cards (Interactive results)
                  if (!isUser && structured != null) ...[
                    // 1. Product Cards
                    if (structured.hasProducts) ...[
                      const SizedBox(height: 6),
                      ...structured.products.map((p) => AIProductCard(product: p)),
                    ],

                    // 2. Receipt Cards
                    if (structured.hasReceipts) ...[
                      const SizedBox(height: 6),
                      ...structured.receipts.map((r) => AIReceiptCard(receipt: r)),
                    ],

                    // 3. Warranty Cards
                    if (structured.hasWarranties) ...[
                      const SizedBox(height: 6),
                      ...structured.warranties.map((w) => AIWarrantyCard(warranty: w)),
                    ],

                    // 4. Financial Summary Card
                    if (structured.hasSummary) ...[
                      const SizedBox(height: 6),
                      AISummaryCard(summary: structured.summary!),
                    ],

                    // 5. Category Breakdown Card
                    if (structured.hasCategories) ...[
                      const SizedBox(height: 6),
                      AICategoryBreakdownCard(categories: structured.categories),
                    ],

                    // 6. Action button if opened
                    if (structured.action != null && structured.action!.targetReceiptId != null) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => context.push('/receipts/details/${structured.action!.targetReceiptId}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66F2C1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF66F2C1).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF66F2C1)),
                              const SizedBox(width: 8),
                              Text(
                                'Tap to open Receipt #${structured.action!.targetReceiptId}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF66F2C1),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF66F2C1)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 7. Suggested Follow-up chips
                    if (structured.suggestedFollowUps.isNotEmpty)
                      AIFollowUpChips(
                        suggestions: structured.suggestedFollowUps,
                        onSelected: _sendMessage,
                      ),
                  ],
                ],
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_outline, color: AppColors.secondary, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
            const TypingIndicatorDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final text = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(text),
              labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(text),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _textController,
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(color: AppColors.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Ask about products, receipts, prices...',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicatorDots extends StatefulWidget {
  const TypingIndicatorDots({super.key});

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots> with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    for (int i = 0; i < 3; i++) {
      final start = 0.2 * i;
      final end = start + 0.6;
      _animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _animations[index].value;
              final double scale = 1.0 + (0.3 * math.sin(val * math.pi));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.3 + (0.7 * math.sin(val * math.pi))),
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              );
            },
          );
        }),
      ),
    );
  }
}

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> spans = [];

    for (final line in lines) {
      if (line.trim().startsWith('* ') || line.trim().startsWith('- ')) {
        final content = line.substring(line.indexOf(' ') + 1);
        spans.add(
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Expanded(
                  child: RichText(
                    text: _parseBoldText(content, style),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
              text: _parseBoldText(line, style),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spans,
    );
  }

  TextSpan _parseBoldText(String text, TextStyle? baseStyle) {
    final parts = text.split('**');
    final List<TextSpan> children = [];
    bool isBold = false;

    for (final part in parts) {
      children.add(
        TextSpan(
          text: part,
          style: isBold
              ? (baseStyle ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF66F2C1))
              : baseStyle,
        ),
      );
      isBold = !isBold;
    }

    return TextSpan(children: children);
  }
}
