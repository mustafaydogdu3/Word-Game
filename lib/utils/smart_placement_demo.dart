import '../services/smart_word_placement_service.dart';

class SmartPlacementDemo {
  static void runDemo() {
    print('=== Smart Word Placement Demo ===\n');

    // Demo 1: Level 8 words
    print('Demo 1: Level 8 Words');
    print('Words: [PRINT, RIP, PIN, PIT, TRIP, TIN]');
    print('Letters: [I, N, P, R, T]\n');

    List<String> level8Words = ['PRINT', 'RIP', 'PIN', 'PIT', 'TRIP', 'TIN'];
    List<String> level8Letters = ['I', 'N', 'P', 'R', 'T'];

    Map<String, dynamic> result =
        SmartWordPlacementService.generateSmartPlacements(
          words: level8Words,
          letters: level8Letters,
        );

    _printResults(result);

    // Demo 2: Simple 2-word puzzle
    print('\nDemo 2: Simple 2-Word Puzzle');
    print('Words: [ACT, CAT]');
    print('Letters: [A, C, T]\n');

    List<String> simpleWords = ['ACT', 'CAT'];
    List<String> simpleLetters = ['A', 'C', 'T'];

    Map<String, dynamic> simpleResult =
        SmartWordPlacementService.generateSmartPlacements(
          words: simpleWords,
          letters: simpleLetters,
        );

    _printResults(simpleResult);

    // Demo 3: Complex 6-word puzzle
    print('\nDemo 3: Complex 6-Word Puzzle');
    print('Words: [BLEND, BEND, LEND, LED, DEN, END]');
    print('Letters: [B, D, E, L, N]\n');

    List<String> complexWords = ['BLEND', 'BEND', 'LEND', 'LED', 'DEN', 'END'];
    List<String> complexLetters = ['B', 'D', 'E', 'L', 'N'];

    Map<String, dynamic> complexResult =
        SmartWordPlacementService.generateSmartPlacements(
          words: complexWords,
          letters: complexLetters,
        );

    _printResults(complexResult);

    print('\n=== Demo Complete ===');
  }

  static void _printResults(Map<String, dynamic> result) {
    Map<String, dynamic> placements = result['placements'];
    Map<String, int> gridSize = Map<String, int>.from(result['gridSize']);
    List<dynamic> intersections = result['intersections'];

    print('Grid Size: ${gridSize['rows']}x${gridSize['cols']}');
    print('Total Intersections: ${intersections.length}');
    print('Placements:');

    for (String word in placements.keys) {
      List<dynamic> positions = placements[word];
      print('  $word: ${positions.length} positions');
      for (int i = 0; i < positions.length && i < word.length; i++) {
        Map<String, int> pos = Map<String, int>.from(positions[i]);
        print('    ${word[i]} at [${pos['row']}, ${pos['col']}]');
      }
    }

    if (intersections.isNotEmpty) {
      print('Intersections:');
      for (dynamic intersection in intersections) {
        List<String> words = List<String>.from(intersection['words']);
        String commonLetter = intersection['commonLetter'];
        int pos1 = intersection['positionInFirst'];
        int pos2 = intersection['positionInSecond'];
        print(
          '  ${words[0]}[$pos1] intersects ${words[1]}[$pos2] at "$commonLetter"',
        );
      }
    }
  }

  static void compareWithStaticPlacement() {
    print('\n=== Comparison: Smart vs Static Placement ===\n');

    List<String> words = ['PRINT', 'RIP', 'PIN', 'PIT', 'TRIP', 'TIN'];
    List<String> letters = ['I', 'N', 'P', 'R', 'T'];

    print('Smart Placement:');
    Map<String, dynamic> smartResult =
        SmartWordPlacementService.generateSmartPlacements(
          words: words,
          letters: letters,
        );

    Map<String, int> smartGridSize = Map<String, int>.from(
      smartResult['gridSize'],
    );
    List<dynamic> smartIntersections = smartResult['intersections'];

    print('  Grid Size: ${smartGridSize['rows']}x${smartGridSize['cols']}');
    print('  Intersections: ${smartIntersections.length}');
    print(
      '  Efficiency: ${(smartIntersections.length / words.length * 100).toStringAsFixed(1)}% intersection rate',
    );

    // Calculate grid utilization
    int totalCells = smartGridSize['rows']! * smartGridSize['cols']!;
    int usedCells = 0;
    Map<String, dynamic> placements = smartResult['placements'];
    for (String word in placements.keys) {
      usedCells += word.length;
    }
    double utilization = (usedCells / totalCells * 100);
    print('  Grid Utilization: ${utilization.toStringAsFixed(1)}%');
  }
}
