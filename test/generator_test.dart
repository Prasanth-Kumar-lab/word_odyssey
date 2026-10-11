import 'package:flutter_test/flutter_test.dart';
import 'package:word_odyssey/app/services/dictionary_service.dart';
import 'package:word_odyssey/app/services/puzzle_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generates valid puzzles for many levels', () async {
    final dict = DictionaryService();
    await dict.load();
    final gen = PuzzleGenerator(dict);
    final sw = Stopwatch()..start();
    for (var level = 1; level <= 60; level++) {
      final p = gen.generate(level);
      expect(p.words.length, greaterThanOrEqualTo(3));
      expect(p.rows, lessThanOrEqualTo(10));
      expect(p.cols, lessThanOrEqualTo(9));
      for (final w in p.words) {
        for (final (i, c) in w.cells.indexed) {
          expect(p.letterMap[c.key], w.word[i]);
        }
      }
      if (level % 10 == 1) print('L$level ${p.letters.join()} ${p.rows}x${p.cols} ${p.words.map((w) => w.word).join(",")}');
    }
    print('60 puzzles in ${sw.elapsedMilliseconds}ms');
  });
}
