import EnergyAppBrainCore

@main
struct EnergyAppBrain {
    static func main() {
        print("EnergyAppBrain")
        print("1. Add today's log")
        print("2. Update actual energy")
        print("3. View log summary")
        print("4. Run demo scenarios")
        print("5. Exit")
        print("")

        let mode = ManualEntry.promptString("Choose mode", defaultValue: "1")

        if mode == "5" {
            print("Done.")
        } else if mode == "4" {
            runDemoMode()
        } else if mode == "3" {
            DailyLogStore.printLogSummary(fileName: "energy_logs.csv")
        } else if mode == "2" {
            DailyLogStore.updateMissingActualEnergy(fileName: "energy_logs.csv")
        } else {
            runManualEntryMode()
        }
    }

    private static func runDemoMode() {
        let scenarios = DemoData.makeDemoScenarios()

        for scenario in scenarios {
            ReportPrinter.printReport(for: scenario)
            print("")
            print("----------------------------------------")
            print("")
        }

        let logs = DailyLogStore.makeDailyLogs(from: scenarios)
        DailyLogStore.printDailyLogTable(logs)
        DailyLogStore.saveDailyLogTable(logs, fileName: "energy_logs.csv")
    }

    private static func runManualEntryMode() {
        let entry = ManualEntry.collectDailyLog()

        print("")
        ReportPrinter.printReport(for: entry.input)
        DailyLogStore.appendDailyLog(entry.log, fileName: "energy_logs.csv")
    }
}
