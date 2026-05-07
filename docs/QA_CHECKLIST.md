# LumiShot V1 QA Checklist

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
