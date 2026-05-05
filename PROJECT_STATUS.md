# FlowCheck — Project Status

**Last updated**: 2026-05-04

## What This App Is
Flutter mobile app for river recreationists. Displays USGS streamflow gauge stations on an
interactive map, shows water year percentile band charts (q10/q25/q50/q75/q90), and sends
push notifications when flow at a subscribed station hits flood stage (≥95th percentile).
Android-first. Public (anyone can download from Play Store).

---

## Components

| Component | Status | Notes |
|---|---|---|
| FastAPI backend (`flowcheck-api`) | ✅ Complete | All 46 tests pass |
| Flutter app scaffold + navigation | ✅ Complete | ShellRoute, 4 tabs |
| Map screen with colored markers | ✅ Complete | flutter_map + OSM tiles |
| Station bottom sheet | ✅ Complete | CFS, percentile, bookmark/alert toggles |
| Station detail + chart | ✅ Complete | fl_chart percentile bands |
| Auth (register/login/JWT) | ✅ Complete | Dio interceptor + auto-refresh |
| Favorites / Watchlist | ✅ Complete | API + UI |
| Alert subscriptions | ✅ Complete | API + UI |
| Flood alert scheduler | ✅ Complete | APScheduler hourly job |
| Android build (debug APK) | ✅ Complete | 151MB debug APK builds |
| Firebase Gradle wiring | ✅ Complete | google-services plugin in Gradle |
| FCM manifest + NotificationService | ✅ Complete | BackgroundHandler, token registration |
| `google-services.json` | ⏳ Pending | Downloaded; needs to be placed on VPS |
| `firebase_options.dart` | ⏳ Pending | Run `flutterfire configure` after above |
| Firebase service account JSON | ⏳ Pending | Download from Firebase console → place on VPS |
| API DNS + SSL | ⏳ Pending | `flowcheck-api.3rdplaces.io` |
| API systemd deploy | ⏳ Pending | After DNS + SSL |
| Release APK signing | ⏳ Pending | Keystore not yet generated |
| Current WY data overlay on chart | ⏳ Pending | New API endpoint + chart update |
| App icons | ⏳ Pending | 512×512 for Play Store |
| Play Store submission | ⏳ Pending | Needs icons, screenshots, privacy policy |

---

## Immediate Next Steps (in order)

### 1. Finish Firebase Setup
- Place `google-services.json` at:
  `/home/geoskimoto/projects/flowcheck-app/android/app/google-services.json`
  ```bash
  scp ~/Downloads/google-services.json <vps-user>@<vps-ip>:/home/geoskimoto/projects/flowcheck-app/android/app/
  ```
- Log into Firebase CLI and run flutterfire configure:
  ```bash
  ! firebase login
  ! cd /home/geoskimoto/projects/flowcheck-app && /home/geoskimoto/.pub-cache/bin/flutterfire configure --project=<firebase-project-id> --platforms=android
  ```
  This generates `lib/firebase_options.dart`.

- Download Firebase **service account JSON** from:
  Firebase console → Project Settings → Service Accounts → Generate new private key
  Place it on VPS at: `/home/geoskimoto/projects/flowcheck-api/firebase-credentials.json`
  (path already configured in `flowcheck-api/.env`)

### 2. Deploy flowcheck-api
- Create DNS A record: `flowcheck-api.3rdplaces.io` → VPS IP
- Copy nginx config:
  ```bash
  sudo cp /home/geoskimoto/projects/flowcheck-api/flowcheck-api.3rdplaces.io.conf /etc/nginx/sites-enabled/
  sudo nginx -t && sudo systemctl reload nginx
  ```
- Install SSL:
  ```bash
  sudo clpctl lets-encrypt:install:certificate --domainName=flowcheck-api.3rdplaces.io
  ```
- Enable and start the service:
  ```bash
  sudo systemctl enable --now flowcheck-api
  sudo systemctl status flowcheck-api
  ```
- Run migrations (if not already done):
  ```bash
  cd /home/geoskimoto/projects/flowcheck-api && source venv/bin/activate && alembic upgrade head
  ```

### 3. Update Flutter App API URL
- Once API is live at `https://flowcheck-api.3rdplaces.io`, update the default in:
  `/home/geoskimoto/projects/flowcheck-app/lib/core/config.dart`
  Change `defaultValue: 'http://10.0.2.2:8052'` to the production URL.

### 4. Rebuild APK with Production Config
```bash
export ANDROID_HOME=/home/geoskimoto/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
cd /home/geoskimoto/projects/flowcheck-app
flutter build apk --debug --dart-define=API_BASE_URL=https://flowcheck-api.3rdplaces.io
```

### 5. Release Signing (before Play Store)
```bash
keytool -genkey -v -keystore ~/flowcheck-release.jks \
  -alias flowcheck -keyalg RSA -keysize 2048 -validity 10000
```
Then create `android/key.properties` and update `android/app/build.gradle.kts` signingConfig.

### 6. Play Store Submission
- Google Play Developer account: play.google.com/console ($25 one-time)
- App icon: 512×512 PNG
- Feature graphic: 1024×500 PNG
- Screenshots: min 2, phone size
- Privacy policy URL (required — any app with accounts/auth)
- Build: `flutter build appbundle --release`

---

## Deferred Features (post-launch)
- **Current water-year data overlay**: Chart currently shows historical percentile bands only.
  Needs new API endpoint (`GET /stations/{id}/current-year-discharge`) + Flutter chart update
  to draw the actual current-year daily flow line over the historical bands.
- **iOS support**: Requires Apple Developer account ($99/yr) + Mac for Xcode build
- **US expansion**: Currently PNW (WA state) only. StreamflowOps supports other states.
- **Watchlist condition badges**: Show condition dot on watchlist items

---

## Key File Locations

| File | Path |
|---|---|
| API backend | `/home/geoskimoto/projects/flowcheck-api/` |
| Flutter app | `/home/geoskimoto/projects/flowcheck-app/` |
| API .env | `/home/geoskimoto/projects/flowcheck-api/.env` |
| Systemd unit | `/home/geoskimoto/projects/flowcheck-api/flowcheck-api.service` |
| Nginx config | `/home/geoskimoto/projects/flowcheck-api/flowcheck-api.3rdplaces.io.conf` |
| Android SDK | `/home/geoskimoto/android-sdk/` |
| Flutter SDK | `/home/geoskimoto/flutter/` |
| Debug APK | `/home/geoskimoto/projects/flowcheck-app/build/app/outputs/flutter-apk/app-debug.apk` |
| flutterfire CLI | `/home/geoskimoto/.pub-cache/bin/flutterfire` |
