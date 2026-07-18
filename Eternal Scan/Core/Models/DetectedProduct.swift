//
//  DetectedProduct.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Foundation

struct DetectedProduct: Sendable {
    let brand: String
    let name: String
    let variant: String?
    let size: String?
    let category: String?
    let confidence: Float
}
