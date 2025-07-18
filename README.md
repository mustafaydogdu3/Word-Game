# Word Game

A Flutter word puzzle game with multiple game modes and dynamic grid sizes.

## Features

- **Multiple Game Modes**: 
  - German Mode: Traditional German word puzzles
  - LV Mode: New word puzzles with dynamic grid sizes (3x3 to 5x5)
- **Dynamic Grid Sizes**: Supports different grid configurations based on level complexity
- **Interactive Gameplay**: Drag to connect letters and form words
- **Sound Effects**: Immersive audio feedback for game actions
- **Progress Tracking**: Save and resume game progress for each mode
- **Hint System**: Get helpful hints when stuck

## Game Modes

### German Mode
- Uses `levels_final_de_1_to_10.json`
- Traditional 5x5 grid layout
- German word puzzles with frequency-based difficulty

### LV Mode  
- Uses `word_game_lv.json`
- Dynamic grid sizes (3x3, 4x4, 5x5)
- 10 levels with increasing complexity
- Themed word collections

## How to Play

1. **Select Game Mode**: Choose between German or LV mode in settings
2. **Form Words**: Drag your finger to connect letters in the circle
3. **Find All Words**: Complete all target words to advance to the next level
4. **Use Hints**: Tap the lightbulb icon for helpful hints
5. **Shuffle Letters**: Tap the center shuffle button to rearrange letters

## File Structure

```
assets/
├── json/
│   ├── levels_final_de_1_to_10.json  # German levels
│   └── word_game_lv.json             # LV levels
└── sounds/                           # Audio files
```

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the game

## Development

The game uses:
- **Provider** for state management
- **SharedPreferences** for progress saving
- **AudioPlayers** for sound effects
- Custom JSON parsing for level data

## Testing

Run tests with:
```bash
flutter test
```

## License

This project is a starting point for a Flutter application.
