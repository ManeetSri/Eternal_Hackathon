//
//  VisionService.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import UIKit

final class VisionService: VisionServiceProtocol {
    func analyze(image: UIImage) async throws -> OCRResult {
        OCRResult(extractedText: "", confidence: 0, detectedBarcode: nil, observations: [])
    }
}
