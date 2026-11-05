import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/care_guide_screen.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

/// Number of questions; strings are `quiz_q1`..`quiz_qN` and the matching
/// advice shown for a "no" answer is `quiz_tip1`..`quiz_tipN`.
const int kQuizQuestionCount = 8;

enum QuizVerdict { ready, almost, notYet }

/// Pure scoring so it can be unit-tested.
QuizVerdict quizVerdict(int yesCount) {
  if (yesCount >= kQuizQuestionCount - 1) return QuizVerdict.ready;
  if (yesCount >= kQuizQuestionCount / 2) return QuizVerdict.almost;
  return QuizVerdict.notYet;
}

/// "Am I ready to adopt?" self-check. Works offline, stores nothing.
class AdoptionQuizScreen extends StatefulWidget {
  const AdoptionQuizScreen({super.key});
  @override
  State<AdoptionQuizScreen> createState() => _AdoptionQuizScreenState();
}

class _AdoptionQuizScreenState extends State<AdoptionQuizScreen> {
  final List<bool?> _answers = List.filled(kQuizQuestionCount, null);
  int _index = 0;
  bool _done = false;

  void _answer(bool yes) {
    setState(() {
      _answers[_index] = yes;
      if (_index < kQuizQuestionCount - 1) {
        _index++;
      } else {
        _done = true;
      }
    });
  }

  void _restart() => setState(() {
        _answers.fillRange(0, kQuizQuestionCount, null);
        _index = 0;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    return Scaffold(
      appBar: AppBar(title: Text(t('quiz_title'))),
      body: SafeArea(
        child: _done ? _result(t) : _question(t),
      ),
    );
  }

  Widget _question(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / kQuizQuestionCount,
            color: AppTheme.primary,
            backgroundColor: AppTheme.lightGrey,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text('${_index + 1} / $kQuizQuestionCount',
              style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          const Icon(Icons.pets, size: 56, color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(
            t('quiz_q${_index + 1}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.4),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _answer(true),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(t('quiz_yes')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _answer(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
            ),
            child: Text(t('quiz_no')),
          ),
          if (_index > 0)
            TextButton(
              onPressed: () => setState(() => _index--),
              child: Text(t('quiz_back')),
            ),
        ],
      ),
    );
  }

  Widget _result(String Function(String) t) {
    final yes = _answers.where((a) => a == true).length;
    final verdict = quizVerdict(yes);
    final (icon, color, key) = switch (verdict) {
      QuizVerdict.ready => (Icons.celebration, Colors.green, 'quiz_ready'),
      QuizVerdict.almost => (Icons.trending_up, Colors.orange, 'quiz_almost'),
      QuizVerdict.notYet => (Icons.hourglass_bottom, Colors.redAccent, 'quiz_not_yet'),
    };
    final tips = [
      for (var i = 0; i < kQuizQuestionCount; i++)
        if (_answers[i] == false) t('quiz_tip${i + 1}'),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 12),
        Text('$yes / $kQuizQuestionCount',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        Text(t(key),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, color: AppTheme.textDark, height: 1.5)),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(t('quiz_tips_heading'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          for (final tip in tips)
            Card(
              elevation: 0,
              color: AppTheme.accent.withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline,
                    color: AppTheme.textDark),
                title: Text(tip, style: const TextStyle(height: 1.4)),
              ),
            ),
        ],
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(t('care_guide')),
          onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const CareGuideScreen())),
        ),
        TextButton(onPressed: _restart, child: Text(t('quiz_restart'))),
      ],
    );
  }
}
