/// A single cell position on the crossword board.
class GridCell {
  const GridCell(this.row, this.col);
  final int row;
  final int col;

  String get key => '$row,$col';
}

/// A word laid out on the board.
class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.row,
    required this.col,
    required this.horizontal,
  });

  final String word;
  final int row;
  final int col;
  final bool horizontal;

  List<GridCell> get cells => List.generate(
        word.length,
        (i) => horizontal ? GridCell(row, col + i) : GridCell(row + i, col),
      );

  Map<String, dynamic> toJson() => {'w': word, 'r': row, 'c': col, 'h': horizontal};

  factory PlacedWord.fromJson(Map<dynamic, dynamic> m) => PlacedWord(
        word: m['w'] as String,
        row: m['r'] as int,
        col: m['c'] as int,
        horizontal: m['h'] as bool,
      );
}

/// A complete puzzle: wheel letters + crossword layout.
class Puzzle {
  Puzzle({
    required this.id,
    required this.letters,
    required this.words,
    required this.rows,
    required this.cols,
  }) : letterMap = {
          for (final w in words)
            for (final (i, c) in w.cells.indexed) c.key: w.word[i],
        };

  final String id;
  final List<String> letters;
  final List<PlacedWord> words;
  final int rows;
  final int cols;

  /// cell key -> letter
  final Map<String, String> letterMap;

  PlacedWord? wordOf(String w) {
    for (final p in words) {
      if (p.word == w) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'letters': letters,
        'words': words.map((w) => w.toJson()).toList(),
        'rows': rows,
        'cols': cols,
      };

  factory Puzzle.fromJson(Map<dynamic, dynamic> m) => Puzzle(
        id: m['id'] as String,
        letters: (m['letters'] as List).cast<String>(),
        words: (m['words'] as List).map((e) => PlacedWord.fromJson(e as Map)).toList(),
        rows: m['rows'] as int,
        cols: m['cols'] as int,
      );
}
