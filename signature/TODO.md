# iOS App Release TODO - Progress Update

✅ **Preparations Started**

### 1. Preparations & Edits
- [x] Created TODO.md with plan steps
- [ ] pubspec.yaml: Bump version (pending version input, default 1.0.1+1)
- [ ] ios/Runner.xcodeproj/project.pbxproj: Update PRODUCT_BUNDLE_IDENTIFIER=\"com.example.signature\" → user bundle ID (pending Team ID/bundle ID)
- [ ] `flutter pub get` (run after edits)

### 2. Apple Developer Setup (Manual - Where to find Team ID?)
- Enroll/sign in: https://developer.apple.com/account
- Team ID: After enrolling, go to Membership tab: 10-character alphanumeric (e.g. ABCDE1234F)
  - If no account: Pay $99/year first.
- Register App ID: Certificates > Identifiers > (+)
- Bundle ID: Use reverse domain like com.[yourname].signatures
- Provisioning Profile: Certificates > Profiles > (+), App Store type

### 3. Mac + Xcode Required (Confirmed?)
- `cd ios && open Runner.xcworkspace`
- Runner target > Signing: Select Team, profile
- Product > Archive → Organizer > Distribute App → App Store Connect

### 4. Commands to Run
```
flutter clean
flutter pub get
flutter build ios --release
```

### Pending User Input
- Team ID (10-char)
- Bundle ID (e.g. com.dcurt.signatures)
- Version (e.g. 1.0.1+1)
- Mac/Xcode ready? (Windows can't archive iOS)

**Status:** Waiting for details to edit files. Reply with info to proceed! 
