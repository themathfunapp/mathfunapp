import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../utils/locale_text_helpers.dart';

class QuickMathTrueFalseScreen extends StatefulWidget {
  final String ageGroup;

  const QuickMathTrueFalseScreen({
    super.key,
    required this.ageGroup,
  });

  @override
  State<QuickMathTrueFalseScreen> createState() => _QuickMathTrueFalseScreenState();
}

class _QuickMathTrueFalseScreenState extends State<QuickMathTrueFalseScreen> {
  int _score = 0;
  int _currentQuestion = 1;
  final int _totalQuestions = 10;
  int _timeLeft = 5;

  String _question = '';
  bool _correctAnswer = true;

  bool _isAnswered = false;

  AppLocalizations get _loc =>
      AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

  @override
  void initState() {
    super.initState();
    _generateQuestion();
    _startTimer();
  }

  void _generateQuestion() {
    final random = math.Random();

    final num1 = random.nextInt(10) + 1;
    final num2 = random.nextInt(10) + 1;
    final operation = ['+', '-'][random.nextInt(2)];

    final correctResult = operation == '+' ? num1 + num2 : num1 - num2;

    _correctAnswer = random.nextBool();

    final displayedResult = _correctAnswer
        ? correctResult
        : correctResult + (random.nextBool() ? 1 : -1);

    _question = '$num1 $operation $num2 = $displayedResult';

    setState(() {
      _isAnswered = false;
      _timeLeft = 5;
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isAnswered) {
        setState(() {
          _timeLeft--;
        });

        if (_timeLeft > 0) {
          _startTimer();
        } else {
          _timeUp();
        }
      }
    });
  }

  void _timeUp() {
    setState(() {
      _isAnswered = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ ${_loc.get('time_up')}'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.orange,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context).locale);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE91E63),
              Color(0xFFC2185B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildTimer(),
              const SizedBox(height: 40),
              _buildQuestion(loc),
              const SizedBox(height: 60),
              _buildButtons(loc),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        final hPad = narrow ? 8.0 : 16.0;
        final vPad = narrow ? 8.0 : 16.0;
        final chipHP = narrow ? 10.0 : 16.0;
        final chipVP = narrow ? 6.0 : 8.0;
        final scoreFont = narrow ? 15.0 : 18.0;
        final qFont = narrow ? 14.0 : 16.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          child: Row(
            children: [
              IconButton(
                padding: narrow ? EdgeInsets.zero : null,
                constraints: narrow
                    ? const BoxConstraints(minWidth: 40, minHeight: 40)
                    : null,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: chipHP,
                            vertical: chipVP,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⚡ $_score',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: scoreFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: narrow ? 8 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: chipHP,
                            vertical: chipVP,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_currentQuestion/$_totalQuestions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: qFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: _timeLeft / 5,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Text(
          '$_timeLeft',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '⚡ ${loc.get('quick_decide_title')}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleTextHelpers.ltrMathIsolate(_question),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.get('fast_math_true_false'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnswerButton(
          label: '✅ ${loc.get('fast_math_true')}',
          color: Colors.green,
          answer: true,
        ),
        const SizedBox(width: 20),
        _buildAnswerButton(
          label: '❌ ${loc.get('fast_math_false')}',
          color: Colors.red,
          answer: false,
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required bool answer,
  }) {
    return Opacity(
      opacity: _isAnswered ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: _isAnswered ? null : () => _checkAnswer(answer),
        child: Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _checkAnswer(bool userAnswer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
    });

    final isCorrect = userAnswer == _correctAnswer;

    if (isCorrect) {
      setState(() {
        _score += 10;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_loc.get('correct')}!'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${_loc.get('fast_math_wrong')}'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.red,
        ),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion >= _totalQuestions) {
      _showGameCompleteDialog();
    } else {
      setState(() {
        _currentQuestion++;
      });
      _generateQuestion();
      _startTimer();
    }
  }

  void _showGameCompleteDialog() {
    final loc = _loc;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 ${loc.get('game_session_completed')}'),
        content: Text(
          loc
              .get('total_score_progress')
              .replaceAll('{current}', '$_score')
              .replaceAll('{max}', '${_totalQuestions * 10}'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _currentQuestion = 1;
                _generateQuestion();
                _startTimer();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: Text(loc.get('play_again')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(loc.get('exit')),
          ),
        ],
      ),
    );
  }
}
