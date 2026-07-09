import Foundation

public struct DailyLogStore {
    public static func makeDailyLogs(from inputs: [EnergyInput]) -> [DailyEnergyLog] {
        let actualEnergyRatings = [
            "Bad sleep + alcohol": 3,
            "Good recovery day": 9,
            "High stress workday": 5,
            "Hard training day": 7
        ]

        return inputs.map { input in
            DailyEnergyLog(
                dateLabel: input.dateLabel,
                input: input,
                result: EnergyScorer.calculateEnergy(input: input),
                actualEnergyOutOf10: actualEnergyRatings[input.dateLabel]
            )
        }
    }

    public static func printDailyLogTable(_ logs: [DailyEnergyLog]) {
        print("AI training data preview")
        print(makeDailyLogCSV(from: logs))
    }

    public static func saveDailyLogTable(_ logs: [DailyEnergyLog], fileName: String) {
        let csv = makeDailyLogCSV(from: logs)
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("")
            print("Saved AI training data to \(fileName)")
        } catch {
            print("")
            print("Could not save \(fileName): \(error.localizedDescription)")
        }
    }

    public static func appendDailyLog(_ log: DailyEnergyLog, fileName: String) {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(fileName)
        let row = makeDailyLogCSVRow(from: log)
        let header = "date,sleepHours,alcoholDrinks,lateCaffeine,mood,stress,restingHeartRate,hrv,steps,workoutIntensity,predictedEnergy,actualEnergy"

        do {
            let existingCSV = try? String(contentsOf: fileURL, encoding: .utf8)
            let updatedCSV: String

            if let existingCSV, !existingCSV.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updatedCSV = existingCSV.trimmingCharacters(in: .newlines) + "\n" + row
            } else {
                updatedCSV = header + "\n" + row
            }

            try updatedCSV.write(to: fileURL, atomically: true, encoding: .utf8)
            print("")
            print("Saved manual log to \(fileName)")
        } catch {
            print("")
            print("Could not save manual log: \(error.localizedDescription)")
        }
    }

    public static func updateMissingActualEnergy(fileName: String) {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(fileName)

        do {
            let csv = try String(contentsOf: fileURL, encoding: .utf8)
            var rows = csv
                .split(whereSeparator: \.isNewline)
                .map(String.init)

            guard rows.count > 1 else {
                print("No saved logs found yet.")
                return
            }

            let header = rows[0]
            var dataRows = rows.dropFirst().map(parseCSVRow)
            let missingIndexes = dataRows.indices.filter { index in
                dataRows[index].count > 11 && dataRows[index][11].isEmpty
            }

            guard !missingIndexes.isEmpty else {
                print("No logs are missing actual energy.")
                return
            }

            print("")
            print("Logs missing actual energy:")
            for (displayIndex, rowIndex) in missingIndexes.enumerated() {
                let row = dataRows[rowIndex]
                let date = row[safe: 0] ?? "Unknown date"
                let predictedEnergy = row[safe: 10] ?? "?"
                print("\(displayIndex + 1). \(date) - predicted \(predictedEnergy)/10")
            }

            let choice = promptIntInRange("Choose log to update", range: 1...missingIndexes.count)
            let actualEnergy = promptIntInRange("Actual energy 1-10", range: 1...10)
            let selectedRowIndex = missingIndexes[choice - 1]

            dataRows[selectedRowIndex][11] = "\(actualEnergy)"
            rows = [header] + dataRows.map { row in
                row.map(TextFormatter.escapeCSVValue).joined(separator: ",")
            }

            try rows.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
            print("")
            print("Updated actual energy in \(fileName)")
        } catch {
            print("Could not update \(fileName): \(error.localizedDescription)")
        }
    }

    public static func printLogSummary(fileName: String, fallbackFileName: String = "energy_logs.example.csv") {
        do {
            let source = try loadCSVRowsForReading(fileName: fileName, fallbackFileName: fallbackFileName)
            let rows = source.rows
            let summary = makeLogSummary(from: rows)

            print("")
            if source.fileName != fileName {
                print("Using \(source.fileName) because \(fileName) was not found.")
                print("")
            }
            print("Log summary")
            print("- Total logs: \(summary.totalLogs)")
            print("- Completed logs: \(summary.completedLogs)")
            print("- Missing actual energy: \(summary.missingActualEnergy)")
            print("- Average predicted energy: \(formatOptionalAverage(summary.averagePredictedEnergy))")
            print("- Average actual energy: \(formatOptionalAverage(summary.averageActualEnergy))")
            print("- Lowest actual energy day: \(summary.lowestActualEnergyDay ?? "Not available")")
            print("- Highest actual energy day: \(summary.highestActualEnergyDay ?? "Not available")")
            print("- Recent trend: \(summary.recentTrend)")
        } catch {
            print("Could not read \(fileName): \(error.localizedDescription)")
        }
    }

    public static func printRecentLogs(fileName: String, count: Int = 5, fallbackFileName: String = "energy_logs.example.csv") {
        do {
            let source = try loadCSVRowsForReading(fileName: fileName, fallbackFileName: fallbackFileName)
            let rows = source.rows
            let lines = makeRecentLogLines(from: rows, count: count)

            guard !lines.isEmpty else {
                print("No saved logs found yet.")
                return
            }

            print("")
            if source.fileName != fileName {
                print("Using \(source.fileName) because \(fileName) was not found.")
                print("")
            }
            print("Recent logs")
            for line in lines {
                print(line)
            }
        } catch {
            print("Could not read \(fileName): \(error.localizedDescription)")
        }
    }

    public static func makeLogSummary(from rows: [[String]]) -> LogSummary {
        let dataRows = rows.filter { !$0.isEmpty }
        let completedRows = dataRows.filter { row in
            !(row[safe: 11] ?? "").isEmpty
        }

        let predictedValues = dataRows.compactMap { row in
            Double(row[safe: 10] ?? "")
        }
        let actualValues = completedRows.compactMap { row in
            Double(row[safe: 11] ?? "")
        }
        let lowestRow = completedRows.min { first, second in
            (Double(first[safe: 11] ?? "") ?? 0) < (Double(second[safe: 11] ?? "") ?? 0)
        }
        let highestRow = completedRows.max { first, second in
            (Double(first[safe: 11] ?? "") ?? 0) < (Double(second[safe: 11] ?? "") ?? 0)
        }

        return LogSummary(
            totalLogs: dataRows.count,
            completedLogs: completedRows.count,
            missingActualEnergy: dataRows.count - completedRows.count,
            averagePredictedEnergy: average(predictedValues),
            averageActualEnergy: average(actualValues),
            lowestActualEnergyDay: lowestRow?[safe: 0],
            highestActualEnergyDay: highestRow?[safe: 0],
            recentTrend: recentTrend(from: actualValues)
        )
    }

    public static func makeRecentLogLines(from rows: [[String]], count: Int = 5) -> [String] {
        let recentRows = rows
            .filter { !$0.isEmpty }
            .suffix(count)
            .reversed()

        return recentRows.enumerated().map { index, row in
            let date = row[safe: 0] ?? "Unknown date"
            let sleepHours = row[safe: 1] ?? "?"
            let alcoholDrinks = row[safe: 2] ?? "?"
            let predictedEnergy = row[safe: 10] ?? "?"
            let actualEnergy = row[safe: 11] ?? ""
            let actualText = actualEnergy.isEmpty ? "actual missing" : "actual \(actualEnergy)/10"

            return "\(index + 1). \(date) - sleep \(sleepHours)h, alcohol \(alcoholDrinks), predicted \(predictedEnergy)/10, \(actualText)"
        }
    }

    static func readableLogFileName(
        preferredFileName: String,
        fallbackFileName: String,
        fileExists: (String) -> Bool
    ) -> String {
        if fileExists(preferredFileName) {
            return preferredFileName
        }

        return fallbackFileName
    }

    private static func makeDailyLogCSV(from logs: [DailyEnergyLog]) -> String {
        var rows = [
            "date,sleepHours,alcoholDrinks,lateCaffeine,mood,stress,restingHeartRate,hrv,steps,workoutIntensity,predictedEnergy,actualEnergy"
        ]

        for log in logs {
            rows.append(makeDailyLogCSVRow(from: log))
        }

        return rows.joined(separator: "\n")
    }

    private static func makeDailyLogCSVRow(from log: DailyEnergyLog) -> String {
        let input = log.input
        let appleWatch = input.appleWatch
        let columns = [
            input.dateLabel,
            TextFormatter.formatDecimal(input.sleepHours),
            "\(input.alcoholDrinks)",
            "\(input.hadCaffeineAfter6pm)",
            "\(input.moodOutOf10)",
            "\(input.stressOutOf10)",
            TextFormatter.formatOptionalForCSV(appleWatch.restingHeartRate),
            TextFormatter.formatOptionalForCSV(appleWatch.heartRateVariability),
            TextFormatter.formatOptionalForCSV(appleWatch.steps),
            TextFormatter.formatOptionalForCSV(appleWatch.workoutIntensityOutOf10),
            "\(log.result.predictedEnergyOutOf10)",
            TextFormatter.formatOptionalForCSV(log.actualEnergyOutOf10)
        ]

        return columns.map(TextFormatter.escapeCSVValue).joined(separator: ",")
    }

    private static func loadCSVRowsForReading(fileName: String, fallbackFileName: String) throws -> (rows: [[String]], fileName: String) {
        let selectedFileName = readableLogFileName(
            preferredFileName: fileName,
            fallbackFileName: fallbackFileName,
            fileExists: { candidate in
                let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(candidate)

                return FileManager.default.fileExists(atPath: fileURL.path)
            }
        )

        return (try loadCSVRows(fileName: selectedFileName), selectedFileName)
    }

    private static func loadCSVRows(fileName: String) throws -> [[String]] {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(fileName)
        let csv = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = csv
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .map { parseCSVRow(String($0)) }

        return rows
    }

    private static func average(_ values: [Double]) -> Double? {
        if values.isEmpty {
            return nil
        }

        return values.reduce(0, +) / Double(values.count)
    }

    private static func recentTrend(from actualValues: [Double]) -> String {
        guard actualValues.count >= 2 else {
            return "Not enough data"
        }

        let previous = actualValues[actualValues.count - 2]
        let latest = actualValues[actualValues.count - 1]
        let difference = latest - previous

        if difference >= 1 {
            return "Improving"
        }

        if difference <= -1 {
            return "Declining"
        }

        return "Stable"
    }

    private static func formatOptionalAverage(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return TextFormatter.formatDecimal(value)
    }

    private static func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var isInsideQuotes = false
        var index = row.startIndex

        while index < row.endIndex {
            let character = row[index]

            if character == "\"" {
                let nextIndex = row.index(after: index)

                if isInsideQuotes && nextIndex < row.endIndex && row[nextIndex] == "\"" {
                    currentValue.append("\"")
                    index = row.index(after: nextIndex)
                    continue
                }

                isInsideQuotes.toggle()
            } else if character == "," && !isInsideQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(character)
            }

            index = row.index(after: index)
        }

        values.append(currentValue)
        return values
    }

    private static func promptIntInRange(_ label: String, range: ClosedRange<Int>) -> Int {
        while true {
            print("\(label): ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if let number = Int(value), range.contains(number) {
                return number
            }

            print("Please enter a number from \(range.lowerBound) to \(range.upperBound).")
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
