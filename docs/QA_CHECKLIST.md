# LumiShot V1 QA Checklist

## Capture
- [ ] Region capture works
- [ ] Window capture works
- [ ] Full-screen capture works
- [ ] Scrolling capture works or falls back safely

## Annotation
- [ ] Text annotation
- [ ] Box annotation
- [ ] Arrow annotation
- [ ] Number annotation auto increments
- [ ] Number annotation supports manual edit

## Extraction
- [ ] Image OCR path
- [ ] PDF text-layer extraction path
- [ ] PDF OCR fallback path
- [ ] Web DOM extraction path
- [ ] Web OCR fallback path

## Export
- [ ] PNG export
- [ ] JPEG export
- [ ] TXT export
- [ ] Markdown export

## Stability
- [ ] 30 loops of capture -> annotate -> export without crash
