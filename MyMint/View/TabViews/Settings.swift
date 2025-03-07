//
//  Settings.swift
//  MyMint
//
//  Created by IFang Lee on 5/14/24.
//

import SwiftUI

struct Settings: View {
    /// Visibility Status
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("lockWhenAppGoesBackground") private var lockWhenAppGoesBackground: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("User Name") {
                    TextField("Nanachi", text: $userName)
                }

                Section("App Lock") {
                    Toggle("Enable App Lock", isOn: $isAppLockEnabled)

                    if isAppLockEnabled {
                        Toggle("Lock When App Goes Background", isOn: $lockWhenAppGoesBackground)

                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    Settings()
}
