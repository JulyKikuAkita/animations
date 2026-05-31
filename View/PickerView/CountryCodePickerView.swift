//
//  CountryCodePickerView.swift
//  animation
//
//  ⚠️  REUSABLE COMPONENT, NOT A STANDALONE DEMO. Consumed by
//      `authOTP/View/OTPLoginView.swift:29` as the country-code
//      selector in the OTP login flow. Don't rename or remove
//      without updating that call site.
//
//  Learning point
//  ──────────────
//  Tiny menu-style country-code picker that AUTO-DETECTS the
//  device's region on appear and pre-selects the matching country.
//  ~33 lines total — the entire trick is reading
//  `@Environment(\.locale)` and matching its `region.identifier`
//  against an enumeration of `Locale.isoRegionCodes`.
//
//  Why `.menu` style instead of `.wheel`?
//  ──────────────────────────────────────
//  Country-code lists are long (~250 entries). A wheel is
//  exhausting to scroll; the menu pop-up gets you "search-style"
//  UX for free since iOS 17 added type-ahead inside `Picker(.menu)`.
//
//  Key APIs
//  ────────
//  • `Picker(_:selection:).pickerStyle(.menu)` — declarative menu
//    presentation; iOS 17+ gives type-ahead.
//  • `@Environment(\.locale)` — reads the device's current locale.
//  • `Locale.Region(identifier:).localizedName(...)` — turns ISO
//    region codes into user-facing display names.
//  • `Locale.isoRegionCodes` — the source of truth for the picker
//    item list.
//
//  How to apply
//  ────────────
//  Drop in any auth/onboarding flow that needs a phone-number
//  prefix. Bind `selection` to a parent `@State String`; the parent
//  composes "+\(selection)\(phoneNumber)" for the actual SMS send.
//
//  See also
//  ────────
//  • authOTP/View/OTPLoginView.swift — the consumer.
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
