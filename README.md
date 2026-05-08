# LumiShot

LumiShot is a native macOS capture and text extraction app.

The main window uses a **top toolbar** workflow: pick a capture mode, run **Capture**, then **annotate** from the same bar (rectangle, arrow, text, counter, and extra tools under **More**). The canvas is the primary workspace; region mode shows numeric fields under the toolbar for x, y, width, and height.

**OCR** is available from the menu **LumiShot → Extract OCR** and from a **global shortcut**. Configure the shortcut in **Settings** (gear in the toolbar): use **Record Shortcut** to capture a letter or number plus optional Command, Shift, Option, or Control; **Esc** cancels recording; **Reset to Default** restores Command-E.

## Local Build (Debug)

From the package root:

```bash
cd /path/to/LumiShot
swift test
xcodebuild -workspace .swiftpm/xcode/package.xcworkspace -scheme LumiShot -configuration Debug -destination "platform=macOS" -derivedDataPath build build
```

Latest branch verification for this redesign flow: `swift test` and the debug `xcodebuild` command above both pass.

## Package DMG (Release)

```bash
cd /path/to/LumiShot
chmod +x Scripts/package_dmg.sh
./Scripts/package_dmg.sh
```

If you already have a signing certificate, you can provide it for better macOS permission persistence across reinstall:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./Scripts/package_dmg.sh
```

Output:

- `release/LumiShot.dmg`
