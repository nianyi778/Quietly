//
//  ContentView.swift
//  Quietly
//
//  Created by likai on 2025/12/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        let store = UserDefaultsRuleStore(defaults: UserDefaults(suiteName: "content-preview")!)
        let model = AppModel(ruleStore: store)
        return MenuPopoverView(model: model)
    }
}

#Preview {
    ContentView()
}
