//
//  VisionServiceProtocol.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import UIKit

protocol VisionServiceProtocol: Sendable {

    /// Performs OCR and product detection on the captured image.
    /// - Parameter image: Captured product image.
    /// - Returns: OCR result extracted from the image.
    func analyze(image: UIImage) async throws -> OCRResult
}
