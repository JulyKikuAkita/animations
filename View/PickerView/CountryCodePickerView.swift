//
//  CountryCodePickerView.swift
//  animation
//
import SwiftUI

struct CountryCodePickerView: View {
    /// View properties
    @Binding var selection: Country?
    @State private var countries: [Country] = []
    @Environment(\.locale) var locale
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(countries) { country in
                Text("(\(country.dialCode)) \(country.code)")
                    .tag(country)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .onAppear(perform: getLocales)
        .tint(.primary)
    }

    private func getLocales() {
        guard countries.isEmpty else { return }
        countries = Country.getCountries()
        let localeIdentifier = locale.region?.identifier ?? "US"
        if let selectedCountry = countries.first(where: { $0.code == localeIdentifier }) {
            selection = selectedCountry
        }
    }
}
