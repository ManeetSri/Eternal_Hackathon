//
//  PreviewView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import UIKit
import AVFoundation

final class PreviewView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        videoPreviewLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }
}
