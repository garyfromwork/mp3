# mp3 - FFXI Background Music Controller

**Author:** Garyfromwork
**Version:** 1.0.0
**Commands:** `//mp3` or `//music`

## Overview

mp3 is a background music controller addon for Final Fantasy XI (Windower). It allows you to change the in-game music on the fly, create a favorites list of your preferred tracks, and set a startup song that plays automatically when you load the addon or log in.

Whether you want to hear the nostalgia of Ronfaure while grinding in Escha-Zi'Tah, or set battle music to your favorite intense track, mp3 makes it easy.

## Features

- **Song Browser** - Browse all available FFXI music tracks with pagination
- **Search Function** - Find songs by partial name match
- **Music Type Control** - Set music for day, night, battle, or mount
- **Favorites List** - Save your preferred songs for quick access
- **Shuffle Mode** - Play random songs, with auto-shuffle on a timer
- **Startup Song** - Automatically play a song when the addon loads
- **Persistent Settings** - Favorites and startup settings save between sessions

## Installation

1. Download the mp3 addon
2. Extract to your `Windower/addons/mp3/` folder
3. In-game, load with `//lua load mp3`
4. (Optional) Add to your `Windower/scripts/init.txt` for auto-loading

### File Structure

```
Windower/addons/mp3/
├── mp3.lua           # Main addon file
└── data/
    └── settings.xml  # Saved configuration (auto-generated)
```

## Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `//mp3 play <song>` | Play a song by name or ID |
| `//mp3 play <song> <type>` | Play with specific music type |
| `//mp3 list [page]` | Browse song list (paginated) |
| `//mp3 search <name>` | Search for songs by name |
| `//mp3 status` | Show current status |
| `//mp3 types` | Show music type info |
| `//mp3 help` | Display command help |

### Favorites Commands

| Command | Description |
|---------|-------------|
| `//mp3 favorites` | Show your favorites list |
| `//mp3 fav add <song>` | Add a song to favorites |
| `//mp3 fav remove <song>` | Remove from favorites |
| `//mp3 fav play <#>` | Play favorite by number |
| `//mp3 fav play <#> <type>` | Play favorite with music type |

### Shuffle Commands

| Command | Description |
|---------|-------------|
| `//mp3 shuffle` | Play a random song |
| `//mp3 shuffle fav` | Play random from favorites |
| `//mp3 shuffle on` | Start auto-shuffle mode |
| `//mp3 shuffle on <sec>` | Auto-shuffle every N seconds |
| `//mp3 shuffle fav on` | Auto-shuffle from favorites |
| `//mp3 shuffle off` | Stop auto-shuffle |
| `//mp3 shuffle status` | Show shuffle settings |
| `//mp3 shuffle interval <sec>` | Set shuffle interval |
| `//mp3 shuffle type <0-4>` | Set shuffle music type |
| `//mp3 next` | Skip to next random song |

### Startup Commands

| Command | Description |
|---------|-------------|
| `//mp3 startup <song>` | Set song to play on load |
| `//mp3 startup <song> <type>` | Set startup song with music type |
| `//mp3 startup off` | Disable startup song |

## Music Types

FFXI has different music channels that play in different situations:

| Type | Name | Description |
|------|------|-------------|
| 0 | Day BGM | Background music during daytime |
| 1 | Night BGM | Background music during nighttime |
| 2 | Solo Battle | Combat music when fighting solo |
| 3 | Party Battle | Combat music when in a party |
| 4 | Mount/Chocobo | Music while riding a mount |

By default, songs play on Type 0 (Day BGM). To hear your music during combat, use Type 2 or 3.

## Usage Examples

### Playing a Song

Play Ronfaure music:
```
//mp3 play Ronfaure
```

Play by ID (Ronfaure is ID 10):
```
//mp3 play 10
```

Play a song for battle:
```
//mp3 play "Battle Theme" 2
```

### Searching for Songs

Find all songs with "Battle" in the name:
```
//mp3 search Battle
```

Find songs with "Jeuno":
```
//mp3 search Jeuno
```

### Managing Favorites

Add Ronfaure to favorites:
```
//mp3 fav add Ronfaure
```

Add by ID:
```
//mp3 fav add 10
```

View favorites:
```
//mp3 favorites
```

Play favorite #1:
```
//mp3 fav play 1
```

Play favorite #2 as battle music:
```
//mp3 fav play 2 2
```

Remove from favorites (by name):
```
//mp3 fav remove Ronfaure
```

Remove from favorites (by position):
```
//mp3 fav remove 1
```

### Setting Startup Song

Set Vana'diel March to play on load:
```
//mp3 startup "Vana'diel March"
```

Set startup song with a specific type:
```
//mp3 startup Ronfaure 0
```

Disable startup song:
```
//mp3 startup off
```

### Browsing the Song List

View page 1 of songs:
```
//mp3 list
```

View page 5:
```
//mp3 list 5
```

### Using Shuffle

Play a random song:
```
//mp3 shuffle
```

Play a random song from your favorites:
```
//mp3 shuffle fav
```

Start auto-shuffle (new song every 3 minutes by default):
```
//mp3 shuffle on
```

Auto-shuffle with custom interval (every 2 minutes):
```
//mp3 shuffle on 120
```

Auto-shuffle from favorites only:
```
//mp3 shuffle fav on
```

Skip to the next random song:
```
//mp3 next
```

Stop auto-shuffle:
```
//mp3 shuffle off
```

Set shuffle to play as battle music:
```
//mp3 shuffle type 2
```

Check shuffle status:
```
//mp3 shuffle status
```

## Popular Song IDs

Here's a quick reference of some popular tracks:

| ID | Song Name |
|----|-----------|
| 1 | Vana'diel March |
| 3 | Kingdom of San d'Oria |
| 4 | Republic of Bastok |
| 5 | Federation of Windurst |
| 10 | Ronfaure |
| 11 | Gustaberg |
| 12 | Sarutabaruta |
| 13 | The Grand Duchy of Jeuno |
| 19 | Battle Theme |
| 24 | Mog House |
| 27 | Tough Battle |
| 33 | Shadow Lord |
| 34 | Xarcabard |
| 47 | Victory Fanfare |
| 71 | Run Chocobo, Run! |
| 91 | Seekers of Adoulin |
| 104 | Rhapsodies of Vana'diel |
| 107 | Dynamis |

## Configuration

### Settings File

Settings are automatically saved to `data/settings.xml`:

```xml
<?xml version="1.0" ?>
<settings>
    <global>
        <startup_song>10</startup_song>
        <startup_type>0</startup_type>
        <favorites>
            <f1>10</f1>
            <f2>13</f2>
            <f3>27</f3>
        </favorites>
    </global>
</settings>
```

### Quick Setup

Set up your favorite track to play automatically:

```
//mp3 fav add "Vana'diel March"
//mp3 fav add "Ronfaure"
//mp3 fav add "Tough Battle"
//mp3 startup "Vana'diel March"
```

## Tips

1. **Use IDs for precision** - If a song name has multiple matches, use the ID number instead

2. **Set battle music** - Use type 2 or 3 to hear your music during combat:
   ```
   //mp3 play "Ronfaure" 2
   ```

3. **Quick play** - You can play directly without the "play" command:
   ```
   //mp3 Ronfaure
   ```

4. **Zone changes** - The game will reset music when you zone. Use the startup song feature or manually replay after zoning

5. **Combine with other addons** - mp3 works alongside other music addons like SetBGM

## Technical Details

### How It Works

mp3 uses Windower's `setmusic` command internally, which modifies the music channel packets. The music change is immediate but non-persistent - zoning or certain game events will reset the music.

### Music ID Limitations

- Valid IDs range from 0 to 255
- Not all IDs have associated music (some are silence or unused)
- Some special IDs (like 900 for Distant Worlds) require memory modification and are not supported

### Resources Library

The addon attempts to load song names from Windower's resources library. If unavailable, it uses a built-in fallback list of common tracks.

## Troubleshooting

### Music not changing?

1. Make sure you're logged in and not in a cutscene
2. Try using the song ID instead of name
3. Check that the music type is appropriate (day music won't play at night, battle music won't play outside combat)

### Song not found?

1. Use `//mp3 list` to browse available songs
2. Use `//mp3 search <partial name>` to find songs
3. Check spelling - use quotes for names with spaces: `//mp3 play "Vana'diel March"`

### Startup song not playing?

1. There's a short delay after login before the song plays
2. Ensure you're fully logged in (not at character select)
3. Check that startup is configured: `//mp3 status`

### Settings not saving?

1. Check that the data folder exists
2. Verify file permissions
3. Use `//mp3 status` to confirm settings are recognized

## Changelog

### Version 1.0.0
- Initial release
- Song browser with pagination
- Search functionality
- Favorites list management
- Shuffle mode (random play, auto-shuffle with timer)
- Startup song configuration
- Music type selection (day/night/battle/mount)
- Persistent settings

## Future Plans

- Zone-based automatic music
- Music preview (short play)
- Import/export favorites
- GUI overlay for song selection
