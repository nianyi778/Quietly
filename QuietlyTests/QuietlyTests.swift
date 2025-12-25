//
//  QuietlyTests.swift
//  QuietlyTests
//
//  Created by likai on 2025/12/24.
//

import Testing
@testable import Quietly

struct QuietlyTests {

    @Test func ruleEngine_lidClose_triggersBluetoothOffOnce() async throws {
        let prev = SystemState(
            timestampMs: 1,
            lidClosed: false,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let curr = SystemState(
            timestampMs: 2,
            lidClosed: true,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let actions = await RuleEngine.evaluate(
            prev: prev,
            curr: curr,
            enabledRules: [.lidCloseBluetoothOff]
        )

        #expect(actions == [.setBluetooth(on: false)])
    }

    @Test func ruleEngine_lidClose_noEdge_noAction() async throws {
        let prev = SystemState(
            timestampMs: 1,
            lidClosed: true,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let curr = SystemState(
            timestampMs: 2,
            lidClosed: true,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let actions = await RuleEngine.evaluate(
            prev: prev,
            curr: curr,
            enabledRules: [.lidCloseBluetoothOff]
        )

        #expect(actions.isEmpty)
    }

    @Test func ruleEngine_onBattery_triggersBluetoothOff() async throws {
        let prev = SystemState(
            timestampMs: 1,
            lidClosed: false,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let curr = SystemState(
            timestampMs: 2,
            lidClosed: false,
            onBattery: true,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let actions = await RuleEngine.evaluate(
            prev: prev,
            curr: curr,
            enabledRules: [.onBatteryPowerSave]
        )

        #expect(actions == [.setPowerMode(.low)])
    }

    @Test func ruleEngine_plugIn_triggersPowerModeAuto() async throws {
        let prev = SystemState(
            timestampMs: 1,
            lidClosed: false,
            onBattery: true,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let curr = SystemState(
            timestampMs: 2,
            lidClosed: false,
            onBattery: false,
            externalDisplayConnected: false,
            bluetoothEnabled: true
        )

        let actions = await RuleEngine.evaluate(
            prev: prev,
            curr: curr,
            enabledRules: [.onBatteryPowerSave]
        )

        #expect(actions == [.setPowerMode(.automatic)])
    }

}
