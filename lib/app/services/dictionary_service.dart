import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Loads the word lists bundled in assets.
/// `common` words are used for crossword answers, `all` validates bonus words.
class DictionaryService extends GetxService {
  final List<String> common = [];
  final List<List<int>> commonCounts = [];
  final Set<String> _all = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final results = await Future.wait([
      rootBundle.loadString('assets/data/common.txt'),
      rootBundle.loadString('assets/data/dictionary.txt'),
    ]);
    for (final w in const LineSplitter().convert(results[0])) {
      if (w.isEmpty) continue;
      common.add(w);
      commonCounts.add(letterCounts(w));
    }
    _all
      ..addAll(const LineSplitter().convert(results[1]))
      ..addAll(common);
    _loaded = true;
  }

  bool isWord(String w) => _all.contains(w);

  static List<int> letterCounts(String w) {
    final counts = List<int>.filled(26, 0);
    for (final u in w.codeUnits) {
      final i = u - 97;
      if (i >= 0 && i < 26) counts[i]++;
    }
    return counts;
  }

  static bool canForm(List<int> word, List<int> pool) {
    for (var i = 0; i < 26; i++) {
      if (word[i] > pool[i]) return false;
    }
    return true;
  }
}
