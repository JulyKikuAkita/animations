//
//  storeKitDemoApp.swift
//  StoreKitDemo
//
//  Created by IFang Lee on 5/12/25.
//
//  ───────────────────────────────────────────────────────────────────────
//  This target contains TWO separate StoreKit demos. They use different
//  product types, so each needs its own `.storekit` configuration file
//  selected in the scheme — there's no way to switch at runtime because
//  the StoreKit Test framework binds the config at process launch.
//
//  Demo 1 — Subscription paywall  (default)
//    • Entry point:   SubscriptionPaywallDemoView  (SubscriptionPaywallDemoView.swift)
//    • UI:            `SubscriptionStoreView` with weekly/monthly/yearly tiers
//    • Config file:   StoreKitDemo/Subscription.storekit
//    • Products:      paywall_weekly, paywall_monthly, paywall_yearly
//                     (all auto-renewable subscriptions)
//
//  Demo 2 — Tipping / support-the-developer paywall  (iOS 26+)
//    • Entry point:   TippingPaywallDemoView  (in StoreKitDemo/ios26/)
//    • UI:            `StoreView` in a glass-effect bottom sheet with
//                     emoji tip tiers (🙌 / ☺️ / 😍 / ❤️)
//    • Config file:   StoreKitDemo/consumableTip.storekit
//    • Products:      animation.test.{mini,support,prosupport,promaxsupport}
//                     (all consumables)
//
//  How to switch between demos
//  ───────────────────────────────────────────────────────────────────────
//  Both parts need to change together, otherwise the view hangs on a
//  spinner (wrong product types → product query returns nothing):
//
//    1. Swap the entry point below:
//         SubscriptionPaywallDemoView()  → subscription demo
//         TippingPaywallDemoView()       → tipping demo
//
//    2. Product → Scheme → Edit Scheme… → Run → Options
//       → StoreKit Configuration: pick the matching file:
//         Subscription.storekit     → subscription demo
//         consumableTip.storekit    → tipping demo
//
//    3. Re-run.
//
//  Why not merge both demos into one scheme?
//    A single `.storekit` file can hold both subscriptions *and*
//    consumables, which would match a real App Store Connect setup and
//    let both demos live in one build. Left as two files here so each
//    demo remains self-contained and easy to read in isolation.
//  ───────────────────────────────────────────────────────────────────────

import SwiftUI

@main
struct StoreKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            SubscriptionPaywallDemoView()
        }
    }
}
