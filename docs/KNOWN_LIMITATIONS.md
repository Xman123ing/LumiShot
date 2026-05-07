# Known Limitations (V1)

- Window capture currently snapshots on-screen windows instead of selecting an explicit target window.
- Scrolling capture currently falls back to display snapshot when dedicated scroll session frames are unavailable.
- OCR defaults to native Vision pipeline and may vary by language/layout quality for dense or stylized text.
- Annotation rasterization is basic (shape overlays without rich typography metrics) and will be improved in later iterations.
- Annotation positioning is rendered in canvas coordinates; when the capture preview is heavily letterboxed, overlay alignment can look approximate.
- The main window uses a single top toolbar; the zoom label is not wired to live canvas zoom yet.
- **Backdrop** in the toolbar is not a full backdrop feature yet (user-facing feedback only).
- The global OCR hotkey is registered via Carbon and supports only **A–Z and 0–9** with Command, Shift, Option, and Control. The Settings recorder only accepts those keys; invalid stored values normalize to a default key and registration may fail until the shortcut is valid.
- OCR shortcut recording uses a local key monitor while the Settings view is open; cancel with **Esc** if needed.
