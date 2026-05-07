# LumiShot V1 QA Checklist

## Main window (top toolbar, annotate-first layout)
- [ ] Top toolbar grouping is clear and stable: Capture block, Annotate block (primary + More), Utility block.
- [ ] Mode menu cycles correctly: Region, Window, Full Screen, Scrolling (region shows x/y/w/h fields).
- [ ] Capture succeeds for each mode where permissions allow; toast shows success or failure.
- [ ] After capture, canvas shows the image; empty overlay prompts to annotate from the top toolbar when appropriate.
- [ ] Rectangle, Arrow, Text, Counter add annotations (verify on canvas).
- [ ] More → Floating Pin adds a text annotation; Backdrop shows placeholder feedback only (no full backdrop feature yet).
- [ ] Copy / Save act on the current capture (manual: verify clipboard or saved file) and each action shows toast feedback.
- [ ] Main surface has no standalone OCR button/panel (OCR stays menu/hotkey driven).
- [ ] Zoom label is visible at top-right of the toolbar (currently static percentage readout).
- [ ] Settings opens the settings window.

## OCR shortcut (Settings recorder)
- [ ] **Record Shortcut**: press a letter or number with optional Command, Shift, Option, Control; stored label updates and menu shortcut matches.
- [ ] **Esc** while recording cancels without changing the stored shortcut.
- [ ] **Reset to Default (Command + E)** restores default modifiers and key.
- [ ] After changing the shortcut, global hotkey and **LumiShot → Extract OCR** still trigger OCR (hotkey should re-register when settings persist).
- [ ] Quit and relaunch app; recorded OCR shortcut persists and still triggers region OCR.

## Capture
- [x] Region capture works (automated: `CaptureServiceTests`)
- [x] Window capture works (automated: `CaptureServiceTests`)
- [ ] Full-screen capture works
- [x] Scrolling capture works or falls back safely (automated: `CaptureServiceTests`)

## Annotation
- [x] Text annotation (automated: `AnnotationStoreTests`)
- [x] Box annotation (automated: `AnnotationStoreTests`)
- [x] Arrow annotation (automated: `AnnotationStoreTests`)
- [x] Number annotation auto increments (automated: `AnnotationStoreTests`)
- [x] Number annotation supports manual edit (automated: `AnnotationStoreTests`)

## Extraction
- [x] Image OCR path (automated: `ImageTextExtractorTests`)
- [ ] PDF text-layer extraction path
- [x] PDF OCR fallback path (automated: `ExtractionPipelineTests`)
- [ ] Web DOM extraction path
- [ ] Web OCR fallback path

## Export
- [x] PNG export (automated: `ExportServiceTests`)
- [x] JPEG export (automated: `ExportServiceTests`)
- [x] TXT export (automated: `ExportServiceTests`)
- [x] Markdown export (automated: `ExportServiceTests`)

## Stability
- [ ] 30 loops of capture -> annotate -> export without crash
