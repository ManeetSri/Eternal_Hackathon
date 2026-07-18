//
//  EternalScanWidgetBundle.swift
//  EternalScanWidgetExtension
//

import WidgetKit
import SwiftUI

@main
struct EternalScanWidgetBundle: WidgetBundle {
    var body: some Widget {
        EternalScanWidget()
        MealSearchWidget()
    }
}
