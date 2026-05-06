# LumiShot

LumiShot is a native macOS capture and text extraction app.

## Local Build (Debug)

```bash
cd /Users/pinli/Workshop/LumiShot
swift test
xcodebuild -scheme LumiShot -configuration Debug -destination "platform=macOS" -derivedDataPath build build
```

## Package DMG (Release)

```bash
cd /Users/pinli/Workshop/LumiShot
chmod +x Scripts/package_dmg.sh
./Scripts/package_dmg.sh
```

Output:

- `release/LumiShot.dmg`
