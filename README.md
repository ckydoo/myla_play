# Music Player App

A beautiful and feature-rich music player application built with Flutter, GetX state management, and SQLite database.

## Features

✨ **Core Features:**
- Play, pause, skip, and control music playback
- Beautiful UI with album art display
- Full-screen player with progress bar
- Mini player on home screen
- Add and manage songs
- Favorite songs functionality
- Shuffle and repeat modes
- Background audio playback support

🎵 **Music Management:**
- SQLite database for persistent storage
- Add songs manually
- Delete songs from library
- Mark songs as favorites
- View all songs and favorites separately

🎨 **UI/UX:**
- Material Design 3
- Dark mode support
- Smooth animations
- Responsive layout
- Intuitive controls

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **GetX**: State management and dependency injection
- **SQLite (sqflite)**: Local database storage
- **just_audio**: Audio playback
- **audio_service**: Background audio support

## Project Structure

```
lib/
├── models/
│   ├── song.dart              # Song data model
│   └── playlist.dart          # Playlist data model
├── database/
│   └── database_helper.dart   # SQLite database operations
├── controllers/
│   └── music_player_controller.dart  # GetX controller for music player
├── screens/
│   ├── home_screen.dart       # Main screen with song list
│   ├── player_screen.dart     # Full player screen
│   └── favorites_screen.dart  # Favorites list screen
└── main.dart                  # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone or create the project:**
   ```bash
   flutter create music_player_app
   cd music_player_app
   ```

2. **Copy all project files to their respective locations**

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Configure permissions:**
   - Android permissions are already set in `AndroidManifest.xml`
   - For iOS, add the following to `ios/Runner/Info.plist`:
   ```xml
   <key>NSAppleMusicUsageDescription</key>
   <string>This app needs access to your music library</string>
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
   </array>
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## Usage

### Adding Songs
1. Tap the **+** floating action button on the home screen
2. Enter song details:
   - Song Title
   - Artist Name
   - File Path (local path to music file)
3. Tap "Add" to save

### Playing Music
- Tap any song in the list to start playing
- Use the mini player at the bottom for quick controls
- Tap the mini player to open the full-screen player

### Full Player Controls
- **Play/Pause**: Central button
- **Skip Next/Previous**: Side buttons
- **Seek**: Drag the progress bar
- **Shuffle**: Toggle shuffle mode
- **Repeat**: Cycle through repeat modes (off → all → one)
- **Favorite**: Toggle favorite status

### Managing Favorites
- Tap the heart icon on any song to add/remove from favorites
- Access favorites from the heart icon in the app bar
- Play favorites playlist by tapping any song in favorites

## Database Schema

### Songs Table
```sql
CREATE TABLE songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT,
  filePath TEXT NOT NULL,
  duration INTEGER,
  albumArt TEXT,
  addedDate TEXT NOT NULL,
  isFavorite INTEGER
)
```

### Playlists Table
```sql
CREATE TABLE playlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  createdDate TEXT NOT NULL,
  songIds TEXT
)
```

## Key Components

### MusicPlayerController (GetX)
Manages all music player state and operations:
- Audio playback control
- Playlist management
- Database operations
- UI state management

### DatabaseHelper
Singleton class for SQLite operations:
- CRUD operations for songs
- CRUD operations for playlists
- Favorite management

## Customization

### Changing Theme Colors
Edit the theme in `main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
```

### Adding More Features
Some ideas for extending the app:
- Import songs from device storage
- Create custom playlists
- Equalizer controls
- Sleep timer
- Lyrics display
- Audio visualization
- Cloud sync

## Common Issues & Solutions

### Audio not playing
- Ensure the file path is correct and accessible
- Check storage permissions are granted
- Verify audio file format is supported (mp3, m4a, wav, etc.)

### App crashes on startup
- Run `flutter clean` and `flutter pub get`
- Check all dependencies are properly installed
- Verify minimum SDK version requirements

### Database errors
- Clear app data and reinstall
- Check database initialization in `DatabaseHelper`

## Performance Tips

1. **Large Libraries**: For better performance with many songs, implement pagination
2. **Album Art**: Consider caching album art images
3. **Background Playback**: Properly implement audio_service for seamless background playback

## Dependencies

```yaml
get: ^4.6.6                    # State management
just_audio: ^0.9.36            # Audio playback
audio_service: ^0.18.12        # Background audio
sqflite: ^2.3.0                # SQLite database
path_provider: ^2.1.1          # File system paths
file_picker: ^6.1.1            # File selection
permission_handler: ^11.0.1    # Runtime permissions
on_audio_query: ^2.9.0         # Query device audio files
```

## License

This project is open source and available for personal and commercial use.

## Contributing

Feel free to fork this project and submit pull requests for any improvements!

## Support

For issues and questions:
1. Check the documentation
2. Review common issues section
3. Open an issue on GitHub

---

**Happy Listening! 🎵**
