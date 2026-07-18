//
//  EternalScanWidgetExtensionBundle.swift
//  EternalScanWidgetExtension
//
//  Created by Maneet@MLL on 18/07/26.
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

