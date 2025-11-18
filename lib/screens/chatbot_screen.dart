import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../services/voice_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final ChatbotService _chatbotService = ChatbotService();
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  bool _voiceInputEnabled = false;
  bool _voiceOutputEnabled = false;
  late AnimationController _micAnimationController;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initialize voice service
    _initializeVoice();

    // Welcome message
    _addMessage(
      ChatMessage(
        text:
            '👋 Hello! আমি আপনার Financial Assistant।\n\n'
            'আপনার expense সম্পর্কে যেকোনো প্রশ্ন করুন!\n'
            'উদাহরণ: "আজকের খরচ কত?" বা "help"\n\n'
            '🎤 Voice input available! Tap mic icon.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.greeting,
      ),
    );
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceService.initialize();
      setState(() {
        _voiceInputEnabled = _voiceService.isInitialized;
      });
    } catch (e) {
      print('Voice initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );

    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Get bot response
    try {
      final response = await _chatbotService.processMessage(text);

      setState(() {
        _isTyping = false;
      });

      _addMessage(response);

      // Speak response if voice output enabled
      if (_voiceOutputEnabled && response.text.isNotEmpty) {
        await _speakResponse(response.text);
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
      });

      _addMessage(
        ChatMessage(
          text: 'দুঃখিত, একটা error হয়েছে। আবার try করুন। 😔',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.fallback,
        ),
      );
    }
  }

  Future<void> _startVoiceInput() async {
    if (!_voiceInputEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input not available')),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    try {
      // Show listening dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _micAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_micAnimationController.value * 0.3),
                    child: Icon(
                      Icons.mic,
                      size: 64,
                      color: Colors.red.withOpacity(
                        0.7 + (_micAnimationController.value * 0.3),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Listening...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Speak now'),
            ],
          ),
        ),
      );

      final recognizedText = await _voiceService.startListening(
        timeout: const Duration(seconds: 10),
        onPartialResult: (text) {
          print('Partial: $text');
        },
      );

      Navigator.of(context).pop(); // Close dialog

      setState(() {
        _isListening = false;
      });

      if (recognizedText.isNotEmpty) {
        _messageController.text = recognizedText;
        await _sendMessage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No speech detected. Try again.')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        _isListening = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice input error: $e')));
    }
  }

  Future<void> _speakResponse(String text) async {
    try {
      // Clean text for speech (remove emojis and special characters)
      final cleanText = text.replaceAll(RegExp(r'[^\w\s৳.,!?-]'), '');
      await _voiceService.speak(cleanText, rate: 0.5);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  void _toggleVoiceOutput() {
    setState(() {
      _voiceOutputEnabled = !_voiceOutputEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _voiceOutputEnabled
              ? '🔊 Voice output enabled'
              : '🔇 Voice output disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendQuickReply(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Always ready to help',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _voiceOutputEnabled ? Icons.volume_up : Icons.volume_off,
              color: _voiceOutputEnabled ? Colors.blue : Colors.grey,
            ),
            onPressed: _toggleVoiceOutput,
            tooltip: _voiceOutputEnabled
                ? 'Disable voice output'
                : 'Enable voice output',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Replies (show only when no typing)
          if (!_isTyping && _messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickReply('আজকের খরচ?', Icons.today),
                    const SizedBox(width: 8),
                    _buildQuickReply('গতকালের খরচ?', Icons.history),
                    const SizedBox(width: 8),
                    _buildQuickReply('এই মাসের খরচ?', Icons.calendar_month),
                    const SizedBox(width: 8),
                    _buildQuickReply('Budget advice', Icons.lightbulb),
                    const SizedBox(width: 8),
                    _buildQuickReply('Savings tips', Icons.savings),
                    const SizedBox(width: 8),
                    _buildQuickReply('Help', Icons.help),
                  ],
                ),
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'আপনার প্রশ্ন লিখুন...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_voiceInputEnabled)
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : Colors.grey,
                              ),
                              onPressed: _isListening ? null : _startVoiceInput,
                              tooltip: 'Voice Input',
                            ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? Colors.blue.shade500
        : _getMessageTypeColor(message.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, size: 20, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade500,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickReply(String text, IconData icon) {
    return InkWell(
      onTap: () => _sendQuickReply(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (0.5 - (value - index * 0.2).abs())),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Color _getMessageTypeColor(MessageType type) {
    switch (type) {
      case MessageType.greeting:
        return Colors.green.shade50;
      case MessageType.expense:
        return Colors.blue.shade50;
      case MessageType.category:
        return Colors.purple.shade50;
      case MessageType.advice:
        return Colors.orange.shade50;
      case MessageType.tips:
        return Colors.teal.shade50;
      case MessageType.analysis:
        return Colors.indigo.shade50;
      case MessageType.comparison:
        return Colors.pink.shade50;
      case MessageType.help:
        return Colors.amber.shade50;
      case MessageType.info:
        return Colors.grey.shade100;
      case MessageType.fallback:
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
