import 'dart:math';

import '../models/puzzle_model.dart';
import 'dictionary_service.dart';

typedef _Pos = (int, int);

class _Placement {
  const _Placement(this.word, this.row, this.col, this.horizontal);
  final String word;
  final int row;
  final int col;
  final bool horizontal;

  _Pos cell(int i) => horizontal ? (row, col + i) : (row + i, col);
}

/// Builds random crossword puzzles from a base word's letters.
class PuzzleGenerator {
  PuzzleGenerator(this.dict);

  final DictionaryService dict;
  final Random _rnd = Random();

  static const _maxRows = 10;
  static const _maxCols = 9;

  Puzzle generate(int level) {
    final baseLen = level <= 3
        ? 4
        : level <= 10
            ? 5
            : level <= 25
                ? 6
                : 7;
    final maxWords = min(4 + level ~/ 4, baseLen == 4 ? 5 : 9);

    for (var len = baseLen; len >= 4; len--) {
      final minWords = len == 4 ? 3 : 4;
      final bases = <int>[
        for (var i = 0; i < dict.common.length; i++)
          if (dict.common[i].length == len) i
      ]..shuffle(_rnd);

      for (final bi in bases.take(120)) {
        final base = dict.common[bi];
        final pool = dict.commonCounts[bi];
        final subs = <String>[
          for (var i = 0; i < dict.common.length; i++)
            if (i != bi &&
                dict.common[i].length <= len &&
                DictionaryService.canForm(dict.commonCounts[i], pool))
              dict.common[i]
        ];
        if (subs.length + 1 < minWords) continue;

        // Prefer longer words with a bit of randomness.
        final keyed = {for (final s in subs) s: s.length + _rnd.nextDouble() * 1.6};
        subs.sort((a, b) => keyed[b]!.compareTo(keyed[a]!));
        final candidates = [base, ...subs.take(maxWords * 3)];

        final layout = _bestLayout(candidates, maxWords);
        if (layout != null && layout.length >= minWords) {
          return _build(base, layout);
        }
      }
    }
    throw StateError('Unable to generate puzzle');
  }

  List<_Placement>? _bestLayout(List<String> words, int maxWords) {
    List<_Placement>? best;
    var bestScore = double.negativeInfinity;
    for (var attempt = 0; attempt < 28; attempt++) {
      final rest = words.sublist(1);
      final keyed = {for (final w in rest) w: w.length + _rnd.nextDouble() * 2.5};
      rest.sort((a, b) => keyed[b]!.compareTo(keyed[a]!));
      final placed = _tryLayout([words.first, ...rest], maxWords);
      final score = _score(placed);
      if (score > bestScore) {
        bestScore = score;
        best = placed;
      }
    }
    return best;
  }

  List<_Placement> _tryLayout(List<String> order, int maxWords) {
    final grid = <_Pos, String>{};
    final dirs = <_Pos, int>{};
    final placed = <_Placement>[];

    void put(_Placement p) {
      for (var i = 0; i < p.word.length; i++) {
        final c = p.cell(i);
        grid[c] = p.word[i];
        dirs[c] = (dirs[c] ?? 0) | (p.horizontal ? 1 : 2);
      }
      placed.add(p);
    }

    put(_Placement(order.first, 0, 0, _rnd.nextBool()));

    for (final w in order.skip(1)) {
      if (placed.length >= maxWords) break;
      final options = <(_Placement, int)>[];
      for (final pw in placed) {
        for (var i = 0; i < pw.word.length; i++) {
          for (var j = 0; j < w.length; j++) {
            if (w[j] != pw.word[i]) continue;
            final p = pw.horizontal
                ? _Placement(w, pw.row - j, pw.col + i, false)
                : _Placement(w, pw.row + i, pw.col - j, true);
            final inter = _fits(p, grid, dirs);
            if (inter > 0 && _withinBounds(p, placed)) options.add((p, inter));
          }
        }
      }
      if (options.isEmpty) continue;
      options.shuffle(_rnd);
      options.sort((a, b) => b.$2.compareTo(a.$2));
      put(options.first.$1);
    }
    return placed;
  }

  int _fits(_Placement p, Map<_Pos, String> grid, Map<_Pos, int> dirs) {
    final bit = p.horizontal ? 1 : 2;
    final before = p.horizontal ? (p.row, p.col - 1) : (p.row - 1, p.col);
    final after =
        p.horizontal ? (p.row, p.col + p.word.length) : (p.row + p.word.length, p.col);
    if (grid.containsKey(before) || grid.containsKey(after)) return 0;

    var inter = 0;
    for (var i = 0; i < p.word.length; i++) {
      final c = p.cell(i);
      final existing = grid[c];
      if (existing != null) {
        if (existing != p.word[i] || (dirs[c]! & bit) != 0) return 0;
        inter++;
      } else {
        final n1 = p.horizontal ? (c.$1 - 1, c.$2) : (c.$1, c.$2 - 1);
        final n2 = p.horizontal ? (c.$1 + 1, c.$2) : (c.$1, c.$2 + 1);
        if (grid.containsKey(n1) || grid.containsKey(n2)) return 0;
      }
    }
    return inter;
  }

  (int, int, int, int) _bounds(Iterable<_Placement> ps) {
    var minR = 1 << 30, minC = 1 << 30, maxR = -(1 << 30), maxC = -(1 << 30);
    for (final p in ps) {
      final end = p.cell(p.word.length - 1);
      minR = min(minR, p.row);
      minC = min(minC, p.col);
      maxR = max(maxR, end.$1);
      maxC = max(maxC, end.$2);
    }
    return (minR, minC, maxR, maxC);
  }

  bool _withinBounds(_Placement p, List<_Placement> placed) {
    final (minR, minC, maxR, maxC) = _bounds([...placed, p]);
    return maxR - minR + 1 <= _maxRows && maxC - minC + 1 <= _maxCols;
  }

  double _score(List<_Placement> placed) {
    final (minR, minC, maxR, maxC) = _bounds(placed);
    final rows = maxR - minR + 1, cols = maxC - minC + 1;
    final letters = placed.fold<int>(0, (s, p) => s + p.word.length);
    return placed.length * 100 + letters * 3 - rows * cols * 0.9 - (rows - cols).abs() * 2;
  }

  Puzzle _build(String base, List<_Placement> placed) {
    final (minR, minC, maxR, maxC) = _bounds(placed);
    final letters = base.split('');
    do {
      letters.shuffle(_rnd);
    } while (letters.join() == base && base.length > 1);

    return Puzzle(
      id: '${DateTime.now().microsecondsSinceEpoch}_$base',
      letters: letters,
      words: [
        for (final p in placed)
          PlacedWord(word: p.word, row: p.row - minR, col: p.col - minC, horizontal: p.horizontal)
      ],
      rows: maxR - minR + 1,
      cols: maxC - minC + 1,
    );
  }
}
