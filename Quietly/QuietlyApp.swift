//
//  QuietlyApp.swift
//  Quietly
//
//  Created by likai on 2025/12/24.
//

import AppKit
import SwiftUI

final class QuietlyAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    private var engine: AutomationEngine?
    private var ruleStore: UserDefaultsRuleStore?
    private var actionExecutor: ActionExecutor?
    private var stateReader: DefaultSystemStateReader?

    @MainActor private var model: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched. Setting activation policy...")
        NSApp.setActivationPolicy(.accessory)

        let store = UserDefaultsRuleStore()
        let reader = DefaultSystemStateReader()
        self.ruleStore = store
        self.stateReader = reader

        Task { @MainActor in
            print("Creating StatusBarController...")
            let model = AppModel(ruleStore: store)
            self.model = model

            var statusBarController: StatusBarController!
            statusBarController = StatusBarController(model: model) {
                MenuPopoverView(model: model) {
                    statusBarController?.closePopover()
                }
            }
            self.statusBarController = statusBarController
            
            print("StatusBarController created: \(statusBarController!)")

            let executor = await ActionExecutor()
            self.actionExecutor = executor

            let engine = await AutomationEngine(
                stateReader: reader,
                ruleStore: store,
                executor: executor,
                pollIntervalSeconds: 5,
                callbacks: AutomationEngine.Callbacks(
                    onStateUpdated: { state in
                        model.handleStateUpdated(state)
                    },
                    onActionEvent: { event in
                        model.handleActionEvent(event)
                    }
                )
            )
            self.engine = engine

            Task { @QuietlyEngineActor in
                engine.start()
            }
            print("Engine started.")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        let engine = self.engine
        Task { @QuietlyEngineActor in
            engine?.stop()
        }
    }
}

// MARK: - App Entry Point
@main
struct QuietlyApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = QuietlyAppDelegate()
        app.delegate = delegate
        app.run()
    }
}
