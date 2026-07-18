//
//  UIImage+Resize.swift
//  Eternal Scan
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return image
    }
}
