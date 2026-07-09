# EnergyAppBrain

EnergyAppBrain is a prototype energy prediction project. It combines a Swift app brain with a small Python AI prototype to estimate daily energy from sleep, lifestyle, mood, stress, and Apple Watch-style health metrics.

Status: early prototype.

## What It Does

- Scores daily energy from 0-100.
- Predicts energy from 1-10.
- Explains why the score changed.
- Uses progressive alcohol penalties instead of a flat per-drink penalty.
- Detects recovery strain from low HRV plus elevated resting heart rate.
- Gives recovery, training, sleep, caffeine, and nutrition recommendations.
- Saves daily logs to CSV.
- Lets actual energy be filled in later.
- Uses Python to predict actual energy from logged patterns.
- Keeps private health/lifestyle data out of Git.

## Why This Exists

The long-term idea is an iPhone and Apple Watch app that helps answer:

```text
How much energy am I likely to have today, and what should I do about it?
```

For now, the project focuses on the reusable logic:

- scoring,
- recommendations,
- logging,
- data export,
- AI prediction.

## Current Architecture

```text
Swift command-line app
  -> manual or demo inputs
  -> energy score
  -> recommendations
  -> energy_logs.csv
  -> Python AI prototype
  -> predicted actual energy
```

## Project Structure

```text
EnergyAppBrain/
  Package.swift
  README.md
  .gitignore
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
      ManualEntry.swift
  Tests/
    EnergyAppBrainTests/
      EnergyScorerTests.swift
  ai/
    __init__.py
    train_energy_model.py
    test_energy_model.py
```

## Swift App

Run from the `EnergyAppBrain` folder:

```powershell
swift run
```

The app menu:

```text
1. Add today's log
2. Update actual energy
3. View log summary
4. Run demo scenarios
5. Exit
```

Manual mode asks for:

- day name/date,
- sleep,
- alcohol,
- caffeine,
- mood,
- stress,
- resting heart rate,
- HRV,
- steps,
- active energy,
- exercise minutes,
- workout intensity,
- actual energy.

If actual energy is not known yet, it can be left blank and added later through option 3.

## Python AI Prototype

Run from the `EnergyAppBrain` folder:

```powershell
py ai\train_energy_model.py
```

The Python script:

- reads `energy_logs.csv` if it exists,
- falls back to `energy_logs.example.csv` if private logs do not exist,
- ignores rows where `actualEnergy` is blank,
- prints a data summary,
- predicts actual energy for the latest saved log,
- compares example days to logged days,
- uses nearest-neighbour matching,
- shows similarity scores.

## Tests

Run Swift tests:

```powershell
swift test
```

Run Python tests:

```powershell
py -m unittest ai.test_energy_model
```

## Example Output

```text
Energy score: 39/100
Predicted energy: 4/10

Why this score:
- Starting baseline: +80
- Slept under 7 hours: -10
- Caffeine after 6pm: -10
- Very high stress: -10
- Resting heart rate: -3
- Heart rate variability: -8

Recommendations:
- Recovery: Prioritise hydration, easy movement, and a calmer day if possible.
- Training: Avoid intense training. Choose rest, walking, stretching, or light technique work.
- Sleep: Try to add 30 to 60 minutes of sleep tonight.
```

## Data Privacy

`energy_logs.csv` is ignored by Git because it may contain personal health and lifestyle data.

Commit this file instead:

```text
energy_logs.example.csv
```

That file contains fake sample data so the project works after cloning without exposing private logs.

## Future Direction

Later, this can become an iPhone and Apple Watch app using SwiftUI and HealthKit.

Possible HealthKit inputs:

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

## Roadmap

- Collect more real daily logs.
- Improve the scoring rules from real patterns.
- Upgrade Python from nearest-neighbour matching to a proper machine learning model.
- Convert the Swift command-line flow into a SwiftUI app.
- Add HealthKit and Apple Watch integration on macOS/Xcode.
