@main
struct EnergyAppBrain {
    static func main() {
        print("EnergyAppBrain")
        print("1. Run demo scenarios")
        print("2. Add manual daily log")
        print("3. Update missing actual energy")
        print("")

        let mode = ManualEntry.promptString("Choose mode", defaultValue: "1")

        if mode == "3" {
            DailyLogStore.updateMissingActualEnergy(fileName: "energy_logs.csv")
        } else if mode == "2" {
            runManualEntryMode()
        } else {
            runDemoMode()
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
