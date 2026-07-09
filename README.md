# EnergyAppBrain

EnergyAppBrain is an early prototype for an energy prediction app.

The project has two parts:

- A Swift command-line app that scores energy from sleep, lifestyle, mood, stress, and Apple Watch-style metrics.
- A Python AI prototype that reads exported CSV logs and predicts actual energy from past patterns.

## Project Structure

```text
EnergyAppBrain/
  Package.swift
  energy_logs.example.csv
  Sources/
    EnergyAppBrain/
      EnergyAppBrain.swift
    EnergyAppBrainCore/
      Models.swift
      EnergyScorer.swift
      RecommendationEngine.swift
      DemoData.swift
      ReportPrinter.swift
      DailyLogStore.swift
      Formatter.swift
  Tests/
    EnergyAppBrainTests/
      EnergyScorerTests.swift
  ai/
    train_energy_model.py
```

## Run The Swift App

From the `EnergyAppBrain` folder:

```powershell
swift run
```

## Run The Swift Tests

From the `EnergyAppBrain` folder:

```powershell
swift test
```

The Swift app:

- runs demo health scenarios or accepts a manual daily log,
- calculates an energy score,
- predicts energy out of 10,
- explains why the score changed,
- gives recovery, training, sleep, caffeine, and nutrition recommendations,
- exports `energy_logs.csv`.

When the app starts, choose:

```text
1. Run demo scenarios
2. Add manual daily log
3. Update missing actual energy
```

Manual mode asks for a day name/date, sleep, alcohol, caffeine, mood, stress, Apple Watch-style metrics, and optional actual energy. It then appends the row to `energy_logs.csv`.

Update mode shows saved rows where `actualEnergy` is blank and lets you fill in the final rating later.

## Run The Python AI Prototype

From the `EnergyAppBrain` folder:

```powershell
py ai\train_energy_model.py
```

The Python script:

- reads `energy_logs.csv` if it exists, otherwise falls back to `energy_logs.example.csv`,
- ignores rows where `actualEnergy` is blank,
- prints a data summary,
- compares example days to logged days,
- predicts actual energy,
- shows the closest matches and similarity scores.

## Current Data Flow

```text
Swift demo inputs
  -> energy score
  -> recommendations
  -> energy_logs.csv
  -> Python AI prototype
  -> predicted actual energy
```

## Future App Direction

Later, the Swift app can become an iPhone app that reads real Apple Watch data through HealthKit.

Possible Apple Watch / HealthKit inputs:

- sleep duration,
- resting heart rate,
- HRV,
- steps,
- active energy,
- exercise minutes,
- workouts.

Manual inputs will still be useful for things Apple Watch cannot reliably know:

- alcohol,
- caffeine,
- mood,
- stress.

## Next Ideas

- Add more real daily logs.
- Fill in `actualEnergy` whenever possible so Python has training data.
- Upgrade Python from nearest-neighbour matching to a real machine learning model.
- Later convert the Swift logic into an iPhone app with SwiftUI and HealthKit.

## GitHub Privacy

`energy_logs.csv` is ignored by Git because it may eventually contain personal health and lifestyle data.

Commit `energy_logs.example.csv` instead. It contains fake sample data so the project still runs after cloning.
