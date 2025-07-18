import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_game/services/word_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordService LV Integration Tests', () {
    test('should load LV levels correctly', () async {
      // Mock the rootBundle to return test data
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async => 'test',
          );

      // Load the LV words
      await WordService.loadLVWords();

      // Check if levels are loaded
      expect(WordService.totalLVLevels, greaterThan(0));

      // Check if we can get level data
      final level1 = WordService.getLVLevelData(1);
      expect(level1, isNotNull);
      expect(level1!.level, equals(1));
      expect(level1.theme, isNotEmpty);
      expect(level1.words, isNotEmpty);
      expect(level1.letters, isNotEmpty);
    });

    test('should generate puzzle for LV level', () async {
      await WordService.loadLVWords();

      final puzzle = WordService.generatePuzzleForLVLevel(1);

      expect(puzzle, isNotNull);
      expect(puzzle.targetWords, isNotEmpty);
      expect(puzzle.letters, isNotEmpty);
      expect(puzzle.theme, isNotEmpty);
      expect(puzzle.level, equals(1));
    });

    test('should handle different grid sizes', () async {
      await WordService.loadLVWords();

      // Check different levels for different grid sizes
      for (int i = 1; i <= WordService.totalLVLevels && i <= 5; i++) {
        final level = WordService.getLVLevelData(i);
        if (level != null) {
          expect(level.gridSize, isNotEmpty);
          expect(level.gridSize.length, equals(2)); // Should have [rows, cols]
          expect(level.gridSize[0], greaterThan(0));
          expect(level.gridSize[1], greaterThan(0));
        }
      }
    });
  });
}
