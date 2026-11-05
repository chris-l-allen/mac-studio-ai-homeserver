import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("usage: qrcode.swift <text> <output.png>\n", stderr)
    exit(1)
}
let text = args[1]
let outPath = args[2]

let filter = CIFilter.qrCodeGenerator()
filter.message = text.data(using: .utf8)!
filter.correctionLevel = "M"
guard let ci = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)) else {
    fputs("failed to generate qr\n", stderr)
    exit(1)
}
let rep = NSCIImageRep(ciImage: ci)
let img = NSImage(size: rep.size)
img.addRepresentation(rep)
guard let tiff = img.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("failed to encode png\n", stderr)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
