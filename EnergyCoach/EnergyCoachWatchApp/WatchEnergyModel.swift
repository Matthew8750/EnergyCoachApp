//
//  WatchEnergyModel.swift
//  EnergyCoachWatchApp
//
//  Created by Codex on 14/07/2026.
//

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class WatchEnergyModel: NSObject, ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var recoveryRisk = "Open iPhone App"
    @Published private(set) var message = "Your latest score will appear after Energy Coach updates on your iPhone."
    @Published private(set) var isRefreshing = false
    @Published private(set) var connectionStatus = "Connecting"
    @Published private(set) var lastUpdatedText = "Waiting for update"

#if canImport(WatchConnectivity)
    private let session: WCSession?
    private var autoRefreshTask: Task<Void, Never>?

    deinit {
        autoRefreshTask?.cancel()
    }

    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }

        super.init()

        session?.delegate = self
        session?.activate()

        if let context = session?.receivedApplicationContext, !context.isEmpty {
            apply(context)
        }

        requestLatestScore()
        startAutoRefresh()
    }

    func requestLatestScore() {
        guard let session else {
            connectionStatus = "Unavailable"
            isRefreshing = false
            return
        }

        connectionStatus = session.isReachable ? "iPhone Reachable" : "Open iPhone App"
        isRefreshing = true

        if !session.receivedApplicationContext.isEmpty {
            apply(session.receivedApplicationContext)
        }

        guard session.isReachable else {
            isRefreshing = false
            return
        }

        session.sendMessage(
            ["request": "latestScore"],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.apply(reply)
                    if reply["score"] == nil {
                        self?.connectionStatus = "No Score Sent"
                    }
                    self?.isRefreshing = false
                }
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.connectionStatus = "Open iPhone App"
                    self?.isRefreshing = false
                }
            }
        )
    }

    private func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.requestLatestScore()
            }
        }
    }

    private func apply(_ context: [String: Any]) {
        if let score = intValue(from: context["score"]) {
            self.score = score
        }

        if let recoveryRisk = context["recoveryRisk"] as? String {
            self.recoveryRisk = recoveryRisk
        }

        if let message = context["message"] as? String {
            self.message = message
        }

        if let updatedAt = doubleValue(from: context["updatedAt"]) {
            lastUpdatedText = Self.relativeUpdateText(for: Date(timeIntervalSince1970: updatedAt))
        }

        if context["score"] != nil || context["recoveryRisk"] != nil || context["message"] != nil {
            connectionStatus = "Updated"
        }
    }

    private func intValue(from value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        if let value = value as? String {
            return Int(value)
        }

        return nil
    }

    private func doubleValue(from value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }

        if let value = value as? NSNumber {
            return value.doubleValue
        }

        if let value = value as? String {
            return Double(value)
        }

        return nil
    }

    private static func relativeUpdateText(for date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))

        if seconds < 5 {
            return "Updated just now"
        }

        if seconds < 60 {
            return "Updated \(seconds)s ago"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "Updated \(minutes)m ago"
        }

        let hours = minutes / 60
        return "Updated \(hours)h ago"
    }
#else
    func requestLatestScore() {}
#endif

    static var preview: WatchEnergyModel {
        let model = WatchEnergyModel()
        model.score = 82
        model.recoveryRisk = "Low"
        model.message = "Keep going. Recovery looks solid today."
        model.lastUpdatedText = "Updated just now"
        return model
    }
}

#if canImport(WatchConnectivity)
extension WatchEnergyModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.connectionStatus = session.isReachable ? "iPhone Reachable" : "Open iPhone App"
            self.requestLatestScore()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.connectionStatus = session.isReachable ? "iPhone Reachable" : "Open iPhone App"
            if session.isReachable {
                self.requestLatestScore()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.apply(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.apply(userInfo)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.apply(applicationContext)
        }
    }
}
#endif
