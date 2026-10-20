# Home-screen widget (iPhone)

The code is ready in this folder, but a Widget Extension has to be added as a target in Xcode on a Mac (once only):

1. **Before you start**, rename this folder to `HabitsWidget_src` (so it doesn't clash with the folder Xcode creates).
2. Open `ios/Runner.xcworkspace` in Xcode.
3. **File ▸ New ▸ Target ▸ Widget Extension**
   - Product Name: `HabitsWidget`
   - Uncheck "Include Live Activity", "Include Control" and "Include Configuration App Intent".
   - When asked "Activate scheme?" choose **Cancel** (keep the Runner scheme).
4. Delete the `.swift` files and `Info.plist` that Xcode generated inside `HabitsWidget` (Move to Trash), then drag in the files from `HabitsWidget_src`:
   `HabitsData.swift`, `HabitsWidget.swift`, `AddWaterIntent.swift`, `RestTimerLiveActivity.swift`, `RestTimerAttributes.swift`, `Info.plist`, `HabitsWidget.entitlements`
   (Target Membership = **HabitsWidget**). Then delete `HabitsWidget_src`.
   - ⚠️ **`RestTimerAttributes.swift` only**: in the File Inspector, tick **Runner** as well as HabitsWidget (the app starts the Live Activity and the extension draws it).
5. **HabitsWidget target ▸ General ▸ Minimum Deployments: iOS 16.2** (required for Live Activities)
6. **Signing & Capabilities**:
   - **Runner**: `+ Capability ▸ App Groups ▸ group.com.example.gymapp`, plus `+ Capability ▸ HealthKit`
   - **HabitsWidget**: `+ Capability ▸ App Groups ▸ group.com.example.gymapp`
   - The entitlements files are ready: `Runner/Runner.entitlements` (App Group + HealthKit) and `HabitsWidget/HabitsWidget.entitlements`.
     Make sure **Build Settings ▸ Code Signing Entitlements** for Runner points to `Runner/Runner.entitlements`.
7. **Runner target ▸ Build Phases**: drag the **Embed Foundation Extensions** phase so it sits **above** "Run Script"/"Thin Binary"
   (otherwise you'll get a `Cycle inside Runner` error).
8. `flutter build ios` or Run from Xcode, then long-press the home screen ▸ ➕ ▸ "عاداتي".

## Sizes
| Size | Contents |
|---|---|
| Small | Day-score ring + gym streak + water % |
| Medium | Ring + water bar with a **+250 ml** button (interactive on iOS 17) + tasks/streak/sleep |
| Large | Greeting + everything above + a 5-week habit heatmap |
| Lock screen | Circular gauge for the score, a rectangle (water/streak/tasks), and an inline line |

## How it works
- Flutter (`lib/core/services/home_widget_service.dart`) writes the data to the App Group on every change and reloads the widget.
- The **+250** button (`AddWaterIntent`) stores the amount in `water_pending` without opening the app, and updates the ring immediately;
  the app adds it to its database the next time it opens.
- Tapping the widget opens the app (`habits://home`); the iOS 16 button opens the water screen (`habits://water`).

## Rest timer (Live Activity / Dynamic Island)
- After every set in the workout screen the timer starts automatically (default 90 seconds, changeable to 60/120/180).
- `ios/Runner/AppDelegate.swift` contains `LiveActivityPlugin` (channel `habits/live_activity`), which starts and updates the Activity.
- The counting itself is done by the system (`Text(timerInterval:)`), so it stays accurate even with the app closed; when it finishes it shows "خلصت الراحة" plus a time-sensitive notification.
- Tapping the Dynamic Island opens the gym tab.
- If Live Activities don't appear: Settings ▸ the app ▸ Live Activities must be on.

## Apple Health
- Read-only: steps, sleep (Core/Deep/REM, or "In Bed" without an Apple Watch) and weight.
- Turn it on from the dashboard ("اربط Apple Health") or from Settings.

> ⚠️ Before publishing: change the Bundle ID from `com.example.gymapp`, then update the App Group name in:
> `HabitsData.swift` (habitsAppGroup), `home_widget_service.dart` (appGroupId), and both entitlements files.
