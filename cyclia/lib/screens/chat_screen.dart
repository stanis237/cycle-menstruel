import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  bool _isTyping = false;
  Map<String, dynamic>? _cycleData;

  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Bonjour ! Je suis votre Assistant Cyclia. Comment puis-je vous aider aujourd'hui ?",
      "isUser": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final data = await _apiService.getPredictions();
    if (mounted) setState(() => _cycleData = data);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    
    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate AI thinking
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      String response = _getSmartResponse(text);
      
      setState(() {
        _isTyping = false;
        _messages.add({"text": response, "isUser": false});
      });
      _scrollToBottom();
    });
  }

  String _getSmartResponse(String input) {
    final query = input.toLowerCase();
    final currentCycle = _cycleData?['current_cycle'];
    final phase = currentCycle?['current_phase']?.toString().toLowerCase() ?? "";
    final bool isIrregular = currentCycle?['is_irregular'] ?? false;
    final int day = currentCycle?['current_day'] ?? 0;

    // Emergency Logic
    if (query.contains("oubli") || query.contains("sos") || query.contains("urgence") || (query.contains("rapport") && query.contains("non protégé"))) {
      if (phase.contains("fertile") || phase.contains("ovulation")) {
        return "🚨 ALERTE : Vous êtes en fenêtre fertile. Si vous avez eu un rapport non protégé ou oublié votre pilule, agissez VITE. Rendez-vous dans l'onglet SÉCURITÉ pour le protocole d'urgence.";
      }
      return "En cas d'oubli ou d'accident, la rapidité est clé. Même hors fenêtre fertile, je vous conseille de consulter le guide d'urgence dans l'onglet SÉCURITÉ.";
    }
    
    // Fertility Logic
    if (query.contains("fertile") || query.contains("enceinte") || query.contains("sécurité")) {
      if (phase.contains("fertile") || phase.contains("ovulation")) {
        return "Vous êtes au jour $day, en pleine fenêtre de fertilité. Les chances de grossesse sont ÉLEVÉES. Utilisez une protection si vous souhaitez éviter une grossesse.";
      }
      if (isIrregular) {
        return "Vos cycles étant irréguliers, la prudence est de mise. Même si le calendrier indique '$phase', fiez-vous avant tout à votre glaire cervicale.";
      }
      return "Actuellement, vous êtes en $phase. Le risque est bas, mais n'oubliez pas de noter vos signes physiques pour confirmer votre sécurité.";
    }
    
    // Period / Pain Logic
    if (query.contains("douleur") || query.contains("crampe") || query.contains("règles") || query.contains("mal")) {
      String advice = "Pour soulager les douleurs, une bouillotte et du magnésium sont très efficaces.";
      if (day > 25) advice += " Vos règles arrivent bientôt, commencez à vous reposer dès maintenant.";
      return "Je comprends, c'est une période parfois difficile. $advice Vous pouvez trouver des compléments adaptés dans notre BOUTIQUE.";
    }

    if (query.contains("phase") || query.contains("cycle")) {
      return "Vous êtes au jour $day de votre cycle, en $phase. C'est un moment idéal pour ${_getPhaseTip(phase)}.";
    }

    // Default
    return "Je suis là pour vous aider à comprendre votre cycle. Vous pouvez me poser des questions sur votre fertilité, vos douleurs ou comment gérer votre Mode Blocus !";
  }

  String _getPhaseTip(String phase) {
    if (phase.contains("règles")) return "vous reposer et prendre soin de vous";
    if (phase.contains("fertile")) return "profiter de votre pic d'énergie";
    return "écouter les besoins de votre corps";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Assistant Santé", style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF8E24AA)),
            onPressed: () => _showDisclaimers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg['text'], msg['isUser']);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF8E24AA) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 24),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 20, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Text("Cyclia écrit...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = ["Suis-je fertile ?", "Conseil douleurs", "Détails phase"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(suggestions[index], style: const TextStyle(fontSize: 12, color: Color(0xFF8E24AA))),
              backgroundColor: Colors.white,
              onPressed: () => _handleSubmitted(suggestions[index]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Posez votre question...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFF4A148C),
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _handleSubmitted(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("À propos de l'assistant"),
        content: const Text("Cet assistant utilise vos données de cycle pour vous conseiller. Il n'est pas un professionnel de santé et ne doit pas être utilisé pour un diagnostic médical."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Compris"))],
      ),
    );
  }
}
