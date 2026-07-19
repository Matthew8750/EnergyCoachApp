# Energy Coach Real-Device Release Checklist

## iPhone and HealthKit

- [ ] Delete any earlier development build to test a true first launch.
- [ ] Confirm onboarding appears before any HealthKit permission prompt.
- [ ] Complete onboarding with VoiceOver and large text once.
- [ ] Tap “Update From Health” and confirm Apple’s permission sheet appears.
- [ ] Grant only some categories; confirm the app remains usable with missing values.
- [ ] Deny every category; confirm there is no crash or repeated forced prompt.
- [ ] Re-enable selected access in Health/Settings and refresh successfully.
- [ ] Confirm sleep, resting heart rate, HRV, steps, active energy, and exercise match Health.
- [ ] Confirm the screen updates after returning from the background.
- [ ] Save and update a Daily Check-In.
- [ ] Change each manual input and verify the score responds.
- [ ] Confirm About & Privacy is readable in light and dark mode.
- [ ] Relaunch the app and confirm onboarding does not repeat.
- [ ] Test airplane mode; all core functionality should still work.

## Apple Watch and syncing

- [ ] Power on and unlock the paired Watch; keep Bluetooth and Wi-Fi enabled.
- [ ] Install both the iPhone and Watch apps from the same Xcode build.
- [ ] Open Energy Coach on iPhone, then on Watch.
- [ ] Confirm score, recovery risk, message, and update time match.
- [ ] Change a manual input on iPhone and confirm the Watch updates.
- [ ] Tap Refresh on Watch while the iPhone app is open.
- [ ] Close the iPhone app and confirm the last application context remains visible.
- [ ] Reopen the iPhone app and confirm syncing recovers.
- [ ] Restart both devices and repeat one sync.

## Release evidence

- [ ] Record iPhone model, iOS version, Watch model, and watchOS version.
- [ ] Capture any failure with exact steps and a screen recording.
- [ ] Run one final Archive build after all device fixes.
