//
//  Barcode.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

extension CGSize {
    static func *(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(
            width: lhs.width * rhs.width,
            height: lhs.height * rhs.height
        )
    }
}

struct Barcode: View {
    private let _code: String

    @State private var barcode: UIImage? = nil

    init(_ code: String) {
        self._code = code
    }

    private static var cache: [String: UIImage] = [:]

    static func pregenerate(_ code: String) {
        guard cache[code] == nil else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = renderBarcode(code) {
                DispatchQueue.main.async {
                    cache[code] = image
                }
            }
        }
    }

    private static func renderBarcode(_ code: String) -> UIImage? {
        let context = CIContext()

        guard let data = code.data(using: .ascii) else { return nil }

        let scale = CGFloat(5)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let filter = CIFilter.pdf417BarcodeGenerator()
        filter.message = data

        guard let outputImage = filter.outputImage else { return nil }

        let size = outputImage.extent.size * CGSize(width: scale, height: scale)
        let point = outputImage.extent.origin

        guard let cgImage = context.createCGImage(
            outputImage.transformed(by: transform),
            from: CGRect(origin: point, size: size)
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        VStack {
            if let _barcode = barcode {
                Image(uiImage: _barcode)
                    .resizable()
                    .frame(height: 70)
            } else {
                HStack {}
                    .frame(height: 70)
            }
        }
        .onAppear {
            if let cached = Self.cache[_code] {
                barcode = cached
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let image = Self.renderBarcode(_code) {
                        DispatchQueue.main.async {
                            Self.cache[_code] = image
                            barcode = image
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    Barcode("0000000000000:member")
        .background(Color.blue)
}
