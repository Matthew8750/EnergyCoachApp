//
//  WatchSyncManager.swift
//  EnergyCoach
//
//  Created by Codex on 14/07/2026.
//

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class WatchSyncManager: NSObject, ObservableObject {
#if canImport(WatchConnectivity)
    private let storageKey = "latestWatchEnergyContext"
    private let session: WCSession?
    private var latestContext: [String: Any] = [:]

    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }

        super.init()

        latestContext = UserDefaults.standard.dictionary(forKey: storageKey) ?? [:]
        session?.delegate = self
        session?.activate()
    }

    func update(score: Int, recoveryRisk: String, message: String) {
        guard let session else {
            return
        }

        let context: [String: Any] = [
            "score": score,
            "recoveryRisk": recoveryRisk,
            "message": message,
            "updatedAt": Date().timeIntervalSince1970,
            "updateID": UUID().uuidString
        ]

        latestContext = context
        UserDefaults.standard.set(context, forKey: storageKey)
        try? session.updateApplicationContext(context)
        session.transferUserInfo(context)

        if session.isReachable {
            session.sendMessage(context, replyHandler: nil)
        }
    }
#else
    func update(score: Int, recoveryRisk: String, message: String) {}
#endif
}

#if canImport(WatchConnectivity)
extension WatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            guard !self.latestContext.isEmpty else {
                return
            }

            try? session.updateApplicationContext(self.latestContext)
            session.transferUserInfo(self.latestContext)

            if session.isReachable {
                session.sendMessage(self.latestContext, replyHandler: nil)
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message["request"] as? String == "latestScore" else {
            replyHandler([:])
            return
        }

        Task { @MainActor in
            let context = self.latestContext.isEmpty
                ? (UserDefaults.standard.dictionary(forKey: self.storageKey) ?? [:])
                : self.latestContext

            replyHandler(context)

            guard !context.isEmpty else {
                return
            }

            try? session.updateApplicationContext(context)
            session.transferUserInfo(context)
        }
    }
}
#endif
