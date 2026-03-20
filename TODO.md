# TODO: Fix Signature Pad - IN PROGRESS

## Approved Plan Steps

**Plan Summary:** Debug gestures/capture, improve painter (variable width), validate context, add feedback.

**Steps to Complete:**

### 1. Create/Update TODO.md with progress tracking ✅ (current)
### 2. Edit signature/lib/main.dart with fixes ⏳
   - Add debug prints to gestures
   - Validate context in capture
   - Improve SignaturePainter (variable stroke, smoothness)
   - Add HitTestBehavior.opaque to GestureDetector
   - Visual/status feedback

### 3. Test changes
   - cd signature && flutter pub get
   - flutter run
   - Verify drawing registers (console prints), capture saves PNG/CSV

### 4. attempt_completion once working ✅

**Status:** ✅ Steps 1-2 complete: main.dart updated with debug, validation, capture fix, improved painter, hit test, feedback.

✅ Step 3: flutter pub get executed.

**Status:** Ready for `flutter run` test. Signature pad now has:
- Debug prints on draw
- Better hit testing/opaque gestures
- Variable stroke width painter
- Context validation on capture
- Improved validation/status

Run `cd signature && flutter run` to test drawing/capture/save.

