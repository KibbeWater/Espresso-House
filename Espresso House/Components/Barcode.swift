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
    
    func generateBarcode() {
        let context = CIContext()
        
        guard let data = _code.data(using: .ascii) else {
            return
        }
        
        let scale = CGFloat(5)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let filter = CIFilter.pdf417BarcodeGenerator()
        let invertFilter = CIFilter.colorInvert()
        filter.message = data
        
        if var outputImage = filter.outputImage {
            let size = outputImage.extent.size * CGSize(width: scale, height: scale)
            let point = outputImage.extent.origin
            
            /*if colorScheme == .dark {
                invertFilter.inputImage = outputImage
                outputImage = invertFilter.outputImage ?? outputImage
            }*/
            
            if let cgImage = context.createCGImage(
                outputImage.transformed(by: transform),
                from: CGRect(origin: point, size: size)
            ) {
                self.barcode = UIImage(cgImage: cgImage)
            }
        }
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
            DispatchQueue.global(qos: .background).async {
                generateBarcode()
            }
        }
    }
}

#Preview {
    Barcode("0000000000000:member")
        .background(Color.blue)
}
