import 'dart:math';

import 'package:get/get.dart';

import '../models/puzzle_model.dart';
import '../services/dictionary_service.dart';
import '../services/puzzle_generator.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';

enum FeedbackType {
  correct,
  wrong,
  bonus,
  repeat,
  bonusRepeat,
  noCoins,
  tooShort,
}

class WordFeedback {
  const WordFeedback(this.type, this.word, this.id);
  final FeedbackType type;
  final String word;
  final int id;
}

class WheelLetter {
  const WheelLetter(this.id, this.char);
  final int id;
  final String char;
}

class GameController extends GetxController {
  static const hintCost = 25;
  static const magicCost = 75;
  static const bonusReward = 5;

  final _storage = Get.find<StorageService>();
  final _dict = Get.find<DictionaryService>();
  final _sound = Get.find<SoundService>();
  late final _generator = PuzzleGenerator(_dict);
  final _rnd = Random();

  final puzzle = Rxn<Puzzle>();
  final found = <String>{}.obs;
  final revealed = <String>{}.obs;
  final bonus = <String>{}.obs;
  final wheel = <WheelLetter>[].obs;
  final current = ''.obs;
  final feedback = Rxn<WordFeedback>();
  final coins = 0.obs;
  final level = 1.obs;
  final completed = false.obs;
  final showComplete = false.obs;
  final completedLevel = 1.obs;
  final reward = 0.obs;
  final flashWord = ''.obs;
  final flashTick = 0.obs;
  final soundOn = true.obs;
  final showVisualizer = true.obs;

  /// Per-cell animation delay (ms) used when a cell becomes visible.
  final Map<String, int> revealDelay = {};

  Puzzle? _next;
  int _feedbackId = 0;

  @override
  void onInit() {
    super.onInit();
    coins.value = _storage.coins;
    level.value = _storage.level;
    soundOn.value = _storage.soundOn;
    final saved = _storage.puzzle;
    if (saved != null) {
      _load(
        saved,
        found: _storage.found,
        revealed: _storage.revealed,
        bonus: _storage.bonus,
      );
    } else {
      _load(_generator.generate(level.value));
      _persist();
    }
  }

  void toggleSound() {
    soundOn.toggle();
    _storage.soundOn = soundOn.value;
    if (soundOn.value) _sound.playLetterTap(2);
  }

  void toggleVisualizer() {
    showVisualizer.toggle();
    Haptics.light();
  }

  void onLetterSelected(int count) {
    _sound.playLetterTap(count - 1);
  }

  void _load(
    Puzzle p, {
    Iterable<String> found = const [],
    Iterable<String> revealed = const [],
    Iterable<String> bonus = const [],
  }) {
    revealDelay.clear();
    for (final key in p.letterMap.keys) {
      final parts = key.split(',');
      revealDelay[key] = 250 + (int.parse(parts[0]) + int.parse(parts[1])) * 45;
    }
    this.found
      ..clear()
      ..addAll(found);
    this.revealed
      ..clear()
      ..addAll(revealed);
    this.bonus
      ..clear()
      ..addAll(bonus);
    wheel.assignAll([
      for (var i = 0; i < p.letters.length; i++) WheelLetter(i, p.letters[i]),
    ]);
    current.value = '';
    feedback.value = null;
    flashWord.value = '';
    completed.value = false;
    showComplete.value = false;
    puzzle.value = p;
  }

  void _persist() {
    _storage.coins = coins.value;
    _storage.level = level.value;
    if (completed.value && _next != null) {
      _storage.savePuzzleState(
        puzzle: _next!,
        found: const [],
        revealed: const [],
        bonus: const [],
      );
    } else if (puzzle.value != null) {
      _storage.savePuzzleState(
        puzzle: puzzle.value!,
        found: found,
        revealed: revealed,
        bonus: bonus,
      );
    }
  }

  void _emit(FeedbackType type, [String word = '']) {
    feedback.value = WordFeedback(type, word, ++_feedbackId);
  }

  void startSelection() => feedback.value = null;

  void submit(String w) {
    current.value = '';
    if (completed.value || w.isEmpty) return;
    if (w.length < 3) {
      if (w.length == 2) {
        _emit(FeedbackType.tooShort, w);
        _sound.playWrongWord();
      }
      return;
    }
    final p = puzzle.value!;
    final pw = p.wordOf(w);

    if (pw != null) {
      if (found.contains(w)) {
        flashWord.value = w;
        flashTick.value++;
        _emit(FeedbackType.repeat, w);
        Haptics.light();
        _sound.playWrongWord();
        return;
      }
      _markFound(pw);
      _autoComplete();
      _emit(FeedbackType.correct, w);
      Haptics.success();
      _sound.playWordCorrect();
      _afterProgress();
      return;
    }

    if (_dict.isWord(w)) {
      if (bonus.contains(w)) {
        _emit(FeedbackType.bonusRepeat, w);
        Haptics.light();
        _sound.playWrongWord();
      } else {
        bonus.add(w);
        coins.value += bonusReward;
        _storage.bonusTotal = _storage.bonusTotal + 1;
        _emit(FeedbackType.bonus, w);
        Haptics.success();
        _sound.playBonusWord();
        _persist();
      }
      return;
    }

    _emit(FeedbackType.wrong, w);
    Haptics.error();
    _sound.playWrongWord();
  }

  void _markFound(PlacedWord pw, {int baseDelay = 0}) {
    found.add(pw.word);
    _storage.wordsTotal = _storage.wordsTotal + 1;
    final cells = pw.cells;
    for (var i = 0; i < cells.length; i++) {
      final key = cells[i].key;
      if (!revealed.contains(key)) {
        revealDelay[key] = baseDelay + i * 85;
        revealed.add(key);
      }
    }
  }

  void _autoComplete() {
    final p = puzzle.value!;
    var changed = true;
    while (changed) {
      changed = false;
      for (final w in p.words) {
        if (found.contains(w.word)) continue;
        if (w.cells.every((c) => revealed.contains(c.key))) {
          found.add(w.word);
          _storage.wordsTotal = _storage.wordsTotal + 1;
          changed = true;
        }
      }
    }
  }

  void _afterProgress() {
    final p = puzzle.value!;
    if (found.length >= p.words.length) {
      completed.value = true;
      completedLevel.value = level.value;
      reward.value = 10 + p.words.length * 3;
      coins.value += reward.value;
      level.value++;
      _next = _generator.generate(level.value);
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (completed.value) {
          showComplete.value = true;
          Haptics.success();
          _sound.playVictory();
        }
      });
    }
    _persist();
  }

  void useHint() {
    if (completed.value) return;
    if (coins.value < hintCost) {
      _emit(FeedbackType.noCoins);
      Haptics.error();
      _sound.playWrongWord();
      return;
    }
    final p = puzzle.value!;
    final hidden = <String>{
      for (final w in p.words)
        if (!found.contains(w.word))
          for (final c in w.cells)
            if (!revealed.contains(c.key)) c.key,
    }.toList();
    if (hidden.isEmpty) return;
    final key = hidden[_rnd.nextInt(hidden.length)];
    coins.value -= hintCost;
    revealDelay[key] = 0;
    revealed.add(key);
    Haptics.success();
    _sound.playBonusWord();
    _autoComplete();
    _afterProgress();
  }

  void useMagic() {
    if (completed.value) return;
    if (coins.value < magicCost) {
      _emit(FeedbackType.noCoins);
      Haptics.error();
      _sound.playWrongWord();
      return;
    }
    final remaining = puzzle.value!.words.where((w) => !found.contains(w.word)).toList();
    if (remaining.isEmpty) return;
    final pick = remaining[_rnd.nextInt(remaining.length)];
    coins.value -= magicCost;
    _markFound(pick);
    _autoComplete();
    _emit(FeedbackType.correct, pick.word);
    Haptics.success();
    _sound.playWordCorrect();
    _afterProgress();
  }

  void shuffle() {
    if (wheel.length < 2) return;
    final before = wheel.map((l) => l.id).join(',');
    final l = List<WheelLetter>.of(wheel);
    do {
      l.shuffle(_rnd);
    } while (l.map((e) => e.id).join(',') == before);
    wheel.assignAll(l);
    Haptics.light();
    _sound.playLetterTap(1);
  }

  void nextPuzzle() {
    Haptics.success();
    _sound.playWordCorrect();
    final next = _next ?? _generator.generate(level.value);
    _next = null;
    _load(next);
    _persist();
  }
}
