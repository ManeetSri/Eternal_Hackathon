//
//  EternalScanWidgetBundle.swift
//  Eternal Scan
//

import WidgetKit
import SwiftUI

struct EternalScanWidgetBundle: WidgetBundle {
    var body: some Widget {
        EternalScanWidget()
        QuickScanWidget()
    }
}
