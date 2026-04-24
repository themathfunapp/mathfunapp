import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/section_soundscape.dart';
import '../localization/app_localizations.dart';
import '../models/multipliers_tower_data.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../models/story_invite_payload.dart';
import '../widgets/story_parent_invite_strip.dart';

/// Çarpanlar Kulesi - Ziki'nin Muz Adası'na Yolculuğu
/// Göklerdeki Matematik Hazinesi - Katlar, bölenler, EKOK, EBOB öğrenme
class MultipliersTowerScreen extends StatefulWidget {
  final VoidCallback onBack;
  final StoryInvitePayload? parentPanelStoryInvite;

  const MultipliersTowerScreen({
    super.key,
    required this.onBack,
    this.parentPanelStoryInvite,
  });

  @override
  State<MultipliersTowerScreen> createState() => _MultipliersTowerScreenState();
}

class _MultipliersTowerScreenState extends State<MultipliersTowerScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  late AnimationController _jumpController;
  late AnimationController _shakeController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _cloudController;
  late AnimationController _hintController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _bounceAnimation;

  int _bananas = 0;
  int _currentStep = 0;
  int _comboCount = 0;
  bool _hasShownNoLivesDialog = false;
  bool _sessionReported = false;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  bool _isAnswered = false;
  int _questionType = 0; // 0:kat, 1:bölen, 2:ekok, 3:ebob
  int _targetNumber = 7;
  int _targetB = 0;
  List<int> _stepOptions = [];
  int _correctAnswer = 0;
  TowerLevel _level = TowerLevel.katlarKoyu;
  bool _showHint = false;

  static const Color _skyBlue = Color(0xFF87CEEB);
  static const Color _grassGreen = Color(0xFF90EE90);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _purple = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.castle);

    _jumpController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _jumpAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _jumpController, curve: Curves.easeOut));

    _shakeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _bounceController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _glowController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _cloudController = AnimationController(duration: const Duration(seconds: 25), vsync: this)..repeat();
    _hintController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _updateLevel();
    _generateQuestion();
    _startHintTimer();
  }

  void _startHintTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isAnswered && _stepOptions.isNotEmpty) {
        setState(() => _showHint = true);
        _hintController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _jumpController.dispose();
    _shakeController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _cloudController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _updateLevel() {
    if (_currentStep < 5) _level = TowerLevel.katlarKoyu;
    else if (_currentStep < 15) _level = TowerLevel.ormanDerinlik;
    else if (_currentStep < 25) _level = TowerLevel.bolenlerMagara;
    else if (_currentStep < 35) _level = TowerLevel.ikizlerZirve;
    else if (_currentStep < 45) _level = TowerLevel.kardeslerVadi;
    else _level = TowerLevel.carpanlarAdasi;
  }

  int _lcm(int a, int b) => (a * b) ~/ _gcd(a, b);
  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  List<int> _divisors(int n) {
    final r = <int>[];
    for (int i = 1; i <= n; i++) if (n % i == 0) r.add(i);
    return r;
  }

  void _generateQuestion() {
    final random = math.Random();
    _isAnswered = false;
    _showHint = false;
    _hintController.stop();
    _hintController.reset();

    final levelInfo = levelData[_level]!;
    final type = levelInfo['type'] as String? ?? 'multiples';

    if (type == 'multiples') {
      final nums = levelInfo['numbers'] as List<dynamic>;
      _targetNumber = (nums[random.nextInt(nums.length)] as num).toInt();
      _targetB = 0;
      _questionType = 0;
      final start = _targetNumber * (random.nextInt(4) + 1);
      _correctAnswer = start.clamp(1, 36);
      _stepOptions = [_correctAnswer];
      while (_stepOptions.length < 3) {
        final wrong = _correctAnswer + (random.nextBool() ? 1 : -1) * (random.nextInt(3) + 1);
        final val = wrong.clamp(1, 36);
        if (!_stepOptions.contains(val) && val % _targetNumber != 0) _stepOptions.add(val);
      }
    } else if (type == 'divisors') {
      final nums = levelInfo['numbers'] as List<dynamic>;
      _targetNumber = (nums[random.nextInt(nums.length)] as num).toInt();
      _targetB = 0;
      _questionType = 1;
      final divs = _divisors(_targetNumber);
      _correctAnswer = divs[random.nextInt(divs.length)];
      _stepOptions = [_correctAnswer];
      while (_stepOptions.length < 3) {
        final wrong = (random.nextInt(35) + 1).clamp(1, 36);
        if (!_stepOptions.contains(wrong) && _targetNumber % wrong != 0) _stepOptions.add(wrong);
      }
    } else if (type == 'lcm') {
      final pairs = levelInfo['pairs'] as List<List<int>>;
      final p = pairs[random.nextInt(pairs.length)];
      _targetNumber = p[0];
      _targetB = p[1];
      _questionType = 2;
      _correctAnswer = _lcm(_targetNumber, _targetB);
      _stepOptions = [_correctAnswer];
      while (_stepOptions.length < 3) {
        final wrong = _correctAnswer + (random.nextBool() ? 1 : -1) * (random.nextInt(3) + 1);
        final val = wrong.clamp(1, 36);
        if (!_stepOptions.contains(val) && (val % _targetNumber != 0 || val % _targetB != 0)) _stepOptions.add(val);
      }
    } else if (type == 'gcd') {
      final pairs = levelInfo['pairs'] as List<List<int>>;
      final p = pairs[random.nextInt(pairs.length)];
      _targetNumber = p[0];
      _targetB = p[1];
      _questionType = 3;
      _correctAnswer = _gcd(_targetNumber, _targetB);
      _stepOptions = [_correctAnswer];
      while (_stepOptions.length < 3) {
        final wrong = (random.nextInt(12) + 1).clamp(1, 36);
        if (!_stepOptions.contains(wrong) && (_targetNumber % wrong != 0 || _targetB % wrong != 0)) _stepOptions.add(wrong);
      }
    } else {
      _questionType = random.nextInt(4);
      if (_questionType == 0) {
        _targetNumber = [2, 3, 4, 5, 6, 7, 8, 9][random.nextInt(8)];
        _targetB = 0;
        final start = _targetNumber * (random.nextInt(4) + 1);
        _correctAnswer = start.clamp(1, 36);
      } else if (_questionType == 1) {
        _targetNumber = [12, 15, 16, 18][random.nextInt(4)];
        _targetB = 0;
        final divs = _divisors(_targetNumber);
        _correctAnswer = divs[random.nextInt(divs.length)];
      } else if (_questionType == 2) {
        _targetNumber = [2, 3, 4][random.nextInt(3)];
        _targetB = [3, 4, 5].where((x) => x != _targetNumber).elementAt(random.nextInt(2));
        _correctAnswer = _lcm(_targetNumber, _targetB);
      } else {
        _targetNumber = 12;
        _targetB = 18;
        _correctAnswer = _gcd(_targetNumber, _targetB);
      }
      _stepOptions = [_correctAnswer];
      while (_stepOptions.length < 3) {
        final wrong = (random.nextInt(30) + 1).clamp(1, 36);
        if (!_stepOptions.contains(wrong)) _stepOptions.add(wrong);
      }
    }

    _stepOptions.shuffle(random);
    setState(() {});
    _startHintTimer();
  }

  void _checkAnswer(int selected) {
    if (_isAnswered) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final correct = selected == _correctAnswer;
    setState(() {
      _isAnswered = true;
      _showHint = false;
      _hintController.stop();

      if (correct) {
        _sessCorrect++;
        if (_sessCorrect % 10 == 0) mechanicsService.addCoins(5);
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _comboCount++;
        _bananas++;
        _currentStep++;
        final bonusSteps = _comboCount >= 3 ? 2 : 0;
        _currentStep += bonusSteps;
        if (bonusSteps > 0) _comboCount = 0;
        _updateLevel();

        _jumpController.forward(from: 0).then((_) {
          if (mounted) {
            if (bonusSteps > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🔥 ${bonusSteps + 1} basamak bonus!'), backgroundColor: _purple, behavior: SnackBarBehavior.floating),
              );
            }
            _generateQuestion();
          }
        });
      } else {
        _sessWrong++;
        _runStreak = 0;
        _audio.playAnswerFeedback(false);
        mechanicsService.onWrongAnswer();
        _comboCount = 0;
        _shakeController.forward(from: 0);
        _bounceController.forward(from: 0).then((_) {
          if (mounted) {
            if (!mechanicsService.hasLives) _showGameOver();
            else _generateQuestion();
          }
        });
      }
    });
  }

  void _reportTowerSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final total = _sessCorrect + _sessWrong;
    final q = total < 1 ? 1 : total;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _sessCorrect,
        wrongAnswers: _sessWrong,
        score: _bananas * 10,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('MultipliersTower report error: $e');
    }
  }

  void _showNoLivesDialog() {
    _reportTowerSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('⚡', style: TextStyle(fontSize: 32)), const SizedBox(width: 8), Text(loc.get('lives_finished'))]),
      content: Text(loc.get('no_lives_play')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.get('ok'))), ElevatedButton(onPressed: () { Navigator.pop(ctx); widget.onBack(); }, child: Text(loc.get('profile')))],
    ));
  }

  void _showGameOver() {
    _reportTowerSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🏝️', style: TextStyle(fontSize: 28)), const SizedBox(width: 8), Flexible(child: Text(loc.get('lives_finished'), textAlign: TextAlign.center))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Text(loc.get('no_lives_play')), const SizedBox(height: 16), Text('🍌 $_bananas', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber))]),
      actions: [ElevatedButton(onPressed: () { Navigator.pop(ctx); widget.onBack(); }, child: Text(loc.get('ok')))],
    ));
  }

  String _getLevelName(AppLocalizations loc) {
    switch (_level) {
      case TowerLevel.katlarKoyu: return loc.get('ziki_level_katlar');
      case TowerLevel.ormanDerinlik: return loc.get('ziki_level_orman');
      case TowerLevel.bolenlerMagara: return loc.get('ziki_level_bolenler');
      case TowerLevel.ikizlerZirve: return loc.get('ziki_level_ortak_kat');
      case TowerLevel.kardeslerVadi: return loc.get('ziki_level_ortak_bolen');
      case TowerLevel.carpanlarAdasi: return loc.get('ziki_level_carpanlar');
    }
  }

  String _getHatEmoji() {
    for (var i = zikiHats.length - 1; i >= 0; i--) {
      if (_bananas >= int.parse(zikiHats[i]['muz']!)) return zikiHats[i]['emoji']!;
    }
    return '🧢';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: true);
    if (!mechanicsService.hasLives && !_hasShownNoLivesDialog) {
      _hasShownNoLivesDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _showNoLivesDialog(); });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_skyBlue, Color(0xFFB0E0E6), _grassGreen],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildClouds(),
              Column(
                children: [
                  _buildTopBar(loc),
                  storyParentInviteStrip(widget.parentPanelStoryInvite),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMagicCrystal(loc),
                          const SizedBox(height: 16),
                          _buildLevelBadge(loc),
                          const SizedBox(height: 20),
                          _buildStepOptions(loc),
                          const SizedBox(height: 24),
                          _buildZiki(loc),
                          const SizedBox(height: 16),
                          _buildMuzAdasi(loc),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClouds() {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, child) => Stack(
        children: [
          Positioned(top: 80 + (_cloudController.value * 150) % 150, left: -30 + (_cloudController.value * 80) % 100, child: Opacity(opacity: 0.5, child: Text('☁️', style: TextStyle(fontSize: 50)))),
          Positioned(top: 150 + (_cloudController.value * 120) % 120, right: -20 + (_cloudController.value * 60) % 80, child: Opacity(opacity: 0.4, child: Text('☁️', style: TextStyle(fontSize: 40)))),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst: geri + canlar + muz (HUD); başlık alta taşınır.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<GameMechanicsService?>(
                        builder: (context, m, _) {
                          final lives = m?.maxLives ?? 3;
                          final current = m?.currentLives ?? 3;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              lives,
                              (i) => Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Opacity(
                                  opacity: i < current ? 1.0 : 0.3,
                                  child: const Text('⚡', style: TextStyle(fontSize: 18)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🍌', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('$_bananas', style: _textStyle(Colors.white, size: 14, bold: true)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏝️ ${loc.get('world_multipliers_tower')}',
                  style: _textStyle(Colors.white, size: 18, bold: true),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  loc.get('ziki_going_to_island'),
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicCrystal(AppLocalizations loc) {
    final crystalEmoji = crystalEmojis[_targetNumber] ?? '✨';
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.7 + 0.3 * math.sin(_glowController.value * math.pi * 2);
        final w = MediaQuery.sizeOf(context).width;
        final targetFont = _targetB > 0 ? (w < 340 ? 22.0 : 28.0) : (w < 340 ? 28.0 : 36.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withOpacity(glow), width: 3),
            boxShadow: [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 15 * glow, spreadRadius: glow)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crystalEmoji, style: TextStyle(fontSize: w < 340 ? 30 : 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✨ ${loc.get('multipliers_tower_target')}', style: _textStyle(Colors.white, size: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (_targetB > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('$_targetNumber & $_targetB', style: _textStyle(_gold, size: targetFont, bold: true)),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('$_targetNumber', style: _textStyle(_gold, size: targetFont, bold: true)),
                      ),
                    if (_questionType == 1) Text(loc.get('multipliers_tower_find_divisors'), style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11), maxLines: 3),
                    if (_questionType == 2) Text(loc.get('multipliers_tower_find_lcm'), style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11), maxLines: 3),
                    if (_questionType == 3) Text(loc.get('multipliers_tower_find_gcd'), style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11), maxLines: 3),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: _purple.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white)),
      child: Text('⭐ ${_getLevelName(loc)}', style: _textStyle(Colors.white, size: 14, bold: true)),
    );
  }

  Widget _buildStepOptions(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: _gold.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]),
      child: Column(
        children: [
          Text(loc.get('multipliers_tower_choose_step'), style: _textStyle(_purple, size: 16, bold: true)),
          if (_showHint && !_isAnswered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _gold.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('💭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _questionType == 1 ? loc.get('ziki_hint_divisors').replaceAll('{0}', '$_targetNumber')
                        : _questionType == 2 ? loc.get('ziki_hint_lcm').replaceAll('{0}', '$_targetNumber').replaceAll('{1}', '$_targetB')
                        : _questionType == 3 ? loc.get('ziki_hint_gcd').replaceAll('{0}', '$_targetNumber').replaceAll('{1}', '$_targetB')
                        : loc.get('ziki_hint_multiples').replaceAll('{0}', '$_targetNumber'),
                    style: _textStyle(Colors.brown, size: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final innerW = constraints.maxWidth;
              const gap = 10.0;
              final cardW = ((innerW - 2 * gap) / 3).floorToDouble().clamp(72.0, 108.0);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: _stepOptions.map((n) => _buildStepCard(loc, n, cardW)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(AppLocalizations loc, int number, double cardWidth) {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && mechanicsService.hasLives;
    final isCorrect = number == _correctAnswer;
    final isSelected = _isAnswered && isCorrect;
    final obj = stepObjects[number] ?? {'emoji': '🔢', 'nameKey': null};
    final emojiSize = (cardWidth * 0.34).clamp(26.0, 36.0);
    final numSize = (cardWidth * 0.22).clamp(16.0, 22.0);

    Color bgColor = Colors.white;
    if (_isAnswered) bgColor = isCorrect ? Colors.green.shade100 : Colors.red.shade50;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = !isCorrect && _isAnswered && _shakeController.isAnimating ? 6 * math.sin(_shakeAnimation.value * math.pi * 4) : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: 1.0,
            child: GestureDetector(
              onTap: canTap ? () => _checkAnswer(number) : null,
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.all((cardWidth * 0.1).clamp(6.0, 12.0)),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? Colors.green : _purple.withOpacity(0.4), width: isSelected ? 3 : 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(obj['emoji'] as String, style: TextStyle(fontSize: emojiSize)),
                    SizedBox(height: (cardWidth * 0.04).clamp(2.0, 6.0)),
                    Text('$number', style: _textStyle(Colors.black87, size: numSize, bold: true)),
                    Text(obj['nameKey'] != null ? loc.get(obj['nameKey'] as String) : '$number', style: TextStyle(fontSize: (numSize * 0.45).clamp(9.0, 11.0), color: Colors.grey.shade700), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZiki(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: Listenable.merge([_jumpAnimation, _bounceAnimation]),
      builder: (context, child) {
        double offsetY = 0;
        if (_jumpAnimation.value > 0) offsetY = -50 * math.sin(_jumpAnimation.value * math.pi);
        if (_bounceAnimation.value > 0) offsetY = 25 * math.sin(_bounceAnimation.value * math.pi);
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.brown),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(_getHatEmoji(), style: const TextStyle(fontSize: 24)),
                    Text('🐵', style: TextStyle(fontSize: 56)),
                    Text('Ziki', style: _textStyle(Colors.white, size: 16, bold: true)),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎒 ${loc.get('ziki_bag')}', style: _textStyle(Colors.white, size: 12)),
                    Text('$_bananas 🍌', style: _textStyle(_gold, size: 20, bold: true)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMuzAdasi(AppLocalizations loc) {
    final w = MediaQuery.sizeOf(context).width;
    final islandEmoji = (48 + math.min(_bananas, 12)).toDouble().clamp(44.0, 64.0);
    final titleSize = w < 360 ? 18.0 : 24.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🏝️', style: TextStyle(fontSize: islandEmoji)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.get('ziki_banana_island'),
              style: _textStyle(Colors.white, size: titleSize, bold: true),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);
}
