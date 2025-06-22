# RXPGuides für Turtle WoW

## Installation

1. Kopiere den gesamten `RXPGuides` Ordner nach `World of Warcraft/Interface/AddOns/`
2. Stelle sicher, dass die Datei `RXPGuides-TurtleWoW.toc` vorhanden ist
3. Starte WoW neu oder gib `/reload` ein

## Erste Tests

Nach dem Login solltest du folgende Befehle testen:

- `/rxp test` - Testet ob das Addon korrekt geladen wurde
- `/rxp version` - Zeigt Versionsinformationen
- `/rxp debug` - Aktiviert/Deaktiviert Debug-Modus
- `/rxp help` - Zeigt alle verfügbaren Befehle

## Aktueller Status - Phase 1

✅ **Fertiggestellt:**
- Basis-Struktur für Turtle WoW
- Lua 5.0 kompatible Core
- Event-System (Ace3 Ersatz)
- Utility-Funktionen
- Lokalisierung (DE, EN, FR, ES, RU, CN)
- Slash-Commands
- Timer-System (C_Timer Ersatz)

⏳ **Nächste Schritte:**
- Phase 2: Settings-System
- Phase 3: Guide-Loader
- Phase 4: Quest-Tracking
- Phase 5: pfQuest Integration

## Bekannte Einschränkungen

- Kein drehender Pfeil (GetPlayerFacing() nicht verfügbar)
- Navigation nur über pfQuest möglich
- Nameplate-Scanning auf 20 yards begrenzt

## Debug-Informationen

Wenn Probleme auftreten:
1. Aktiviere Debug-Modus: `/rxp debug`
2. Schaue nach Fehlermeldungen im Chat
3. Prüfe ob pfQuest installiert ist für Navigation

## Entwicklung

Die Turtle WoW Version nutzt:
- **TurtleCore.lua** - Hauptdatei mit Event-System
- **TurtleUtils.lua** - Utility-Funktionen für Lua 5.0
- **TurtleLocale.lua** - Übersetzungen

Alle Änderungen müssen Lua 5.0 und WoW 1.12.1 API kompatibel sein!