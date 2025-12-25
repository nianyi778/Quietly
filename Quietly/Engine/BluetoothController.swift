//
//  BluetoothController.swift
//  Quietly
//
//  Native IOBluetooth API wrapper for controlling Bluetooth power state.
//  Uses private IOBluetooth framework functions (same as blueutil).
//

import Foundation
import IOBluetooth

/// Errors that can occur during Bluetooth operations
public enum BluetoothError: Error, Sendable {
    case notAvailable
    case operationFailed(String)
    case timeout
}

/// Native Bluetooth controller using IOBluetooth private API.
/// Thread-safe and Sendable.
public struct BluetoothController: Sendable {
    
    public init() {}
    
    // MARK: - Availability
    
    /// Check if Bluetooth hardware/preferences are available
    public var isAvailable: Bool {
        let available = IOBluetoothPreferencesAvailable()
        print("[BluetoothController] isAvailable: \(available)")
        return available != 0
    }
    
    // MARK: - Power State
    
    /// Get current Bluetooth power state
    public var isPoweredOn: Bool {
        let state = IOBluetoothPreferenceGetControllerPowerState()
        print("[BluetoothController] isPoweredOn raw value: \(state)")
        return state != 0
    }
    
    /// Set Bluetooth power state
    /// - Parameter on: true to turn on, false to turn off
    /// - Returns: true if state changed successfully, false otherwise
    @discardableResult
    public func setPower(_ on: Bool) -> Bool {
        let targetState = on ? 1 : 0
        
        // Already in desired state
        if IOBluetoothPreferenceGetControllerPowerState() == targetState {
            return true
        }
        
        // Set new state
        IOBluetoothPreferenceSetControllerPowerState(Int32(targetState))
        
        // Wait for state to change (up to 10 seconds, polling every 100ms)
        // This matches blueutil's behavior
        for _ in 0...100 {
            if IOBluetoothPreferenceGetControllerPowerState() == targetState {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        return false
    }
    
    // MARK: - Discoverable State (for future use)
    
    /// Get current discoverable state
    public var isDiscoverable: Bool {
        return IOBluetoothPreferenceGetDiscoverableState() != 0
    }
    
    /// Set discoverable state
    /// - Parameter discoverable: true to make discoverable, false otherwise
    /// - Returns: true if state changed successfully
    @discardableResult
    public func setDiscoverable(_ discoverable: Bool) -> Bool {
        let targetState = discoverable ? 1 : 0
        
        if IOBluetoothPreferenceGetDiscoverableState() == targetState {
            return true
        }
        
        IOBluetoothPreferenceSetDiscoverableState(Int32(targetState))
        
        for _ in 0...100 {
            if IOBluetoothPreferenceGetDiscoverableState() == targetState {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        return false
    }
}
