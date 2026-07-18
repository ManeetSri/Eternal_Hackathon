//
//  OCRResult.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Foundation

struct OCRResult: Sendable {
    let extractedText: String
    let confidence: Float
    let detectedBarcode: String?
    let observations: [String]
}
