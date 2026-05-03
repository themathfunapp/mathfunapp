import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';

/// Sesli Komutlar Ekranı
/// Sesle matematik sorusu çözme ve yardım
class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen>
    with SingleTickerProviderStateMixin {
  final VoiceCommandService _voiceService = VoiceCommandService();
  late AnimationController _pulseController;

  bool _isListening = false;
  String _lastResult = '';
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _pulseController.repeat(reverse: true);
        _feedback = 'Dinliyorum... 🎤';
      } else {
        _pulseController.stop();
        _feedback = '';
      }
    });
  }

  void _simulateVoiceInput(String text) {
    final result = _voiceService.processCommand(text);
    setState(() {
      _lastResult = text;
      _feedback = result.message;
      _isListening = false;
    });
    _pulseController.stop();

    // 2 saniye sonra feedback'i temizle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _feedback = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade800,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildMicrophoneSection(),
                      const SizedBox(height: 32),
                      _buildQuickCommands(),
                      const SizedBox(height: 32),
                      _buildCommandList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            '🎤',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sesli Komutlar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Switch(
            value: _voiceService.isEnabled,
            onChanged: (value) {
              setState(() {
                _voiceService.toggleVoiceCommands(value);
              });
            },
            activeColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneSection() {
    return Column(
      children: [
        // Mikrofon butonu
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 150 + (_isListening ? _pulseController.value * 30 : 0),
                height: 150 + (_isListening ? _pulseController.value * 30 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isListening
                        ? [Colors.red, Colors.red.shade800]
                        : [Colors.amber, Colors.orange],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Colors.amber)
                          .withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: _isListening ? 10 : 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 64,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Durum metni
        Text(
          _isListening ? 'Dinliyorum...' : 'Konuşmak için dokun',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),

        const SizedBox(height: 8),

        // Geri bildirim
        if (_feedback.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _feedback,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),

        // Son komut
        if (_lastResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Son komut: "$_lastResult"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickCommands() {
    final quickCommands = [
      {'text': '5', 'label': 'Beş'},
      {'text': '10', 'label': 'On'},
      {'text': 'ipucu', 'label': '💡 İpucu'},
      {'text': 'tekrar', 'label': '🔄 Tekrar'},
      {'text': 'atla', 'label': '⏭️ Atla'},
      {'text': 'mola', 'label': '⏸️ Mola'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Hızlı Komutlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickCommands.map((cmd) {
            return GestureDetector(
              onTap: () => _simulateVoiceInput(cmd['text']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  cmd['label']!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommandList() {
    final commands = _voiceService.getAvailableCommands();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Tüm Komutlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: commands.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final cmd = commands[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.mic,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  cmd.command,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cmd.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Örnek: ${cmd.example}',
                      style: TextStyle(
                        color: Colors.amber.withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Örnek komutu çalıştır
                  final exampleText = cmd.example.replaceAll('"', '');
                  _simulateVoiceInput(exampleText);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Bilgi notu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sesli komutlar oyun içinde de çalışır! Cevabı söyleyerek veya "ipucu" diyerek yardım alabilirsin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

