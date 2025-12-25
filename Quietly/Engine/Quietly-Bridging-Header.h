//
//  Quietly-Bridging-Header.h
//  Quietly
//
//  IOBluetooth Private API declarations
//  These functions are used by blueutil and other tools to control Bluetooth.
//

#ifndef Quietly_Bridging_Header_h
#define Quietly_Bridging_Header_h

#import <Foundation/Foundation.h>

// IOBluetooth Private API
// These functions are part of IOBluetooth.framework but not publicly documented.

/// Check if Bluetooth preferences/hardware is available
int IOBluetoothPreferencesAvailable(void);

/// Get current Bluetooth power state (1 = on, 0 = off)
int IOBluetoothPreferenceGetControllerPowerState(void);

/// Set Bluetooth power state (1 = on, 0 = off)
void IOBluetoothPreferenceSetControllerPowerState(int state);

/// Get discoverable state (1 = discoverable, 0 = not discoverable)
int IOBluetoothPreferenceGetDiscoverableState(void);

/// Set discoverable state (1 = discoverable, 0 = not discoverable)
void IOBluetoothPreferenceSetDiscoverableState(int state);

#endif /* Quietly_Bridging_Header_h */
