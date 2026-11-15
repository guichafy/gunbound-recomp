// Local Android QA only. Same stdout contract as `tesseract image stdout`.
import Foundation
import Vision
import ImageIO

guard CommandLine.arguments.count >= 2 else {
    fputs("Expected screenshot path\n", stderr)
    exit(2)
}
do {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US"]
    request.usesLanguageCorrection = false
    let handler = VNImageRequestHandler(url: URL(fileURLWithPath: CommandLine.arguments[1]), options: [:])
    try handler.perform([request])
    var recognized = (request.results ?? []).map { ($0, CGRect(x: 0, y: 0, width: 1, height: 1)) }
    // The native bitmap OK sometimes disappears from a full-frame Vision pass.
    // Read the lower-left region independently; accept only an actually
    // recognized OK, and retain its measured bounds instead of a fixed tap.
    if !recognized.contains(where: { $0.0.topCandidates(1).first?.string.range(of: #"\bOK\b"#, options: .regularExpression) != nil }) {
        let detail = VNRecognizeTextRequest()
        detail.recognitionLevel = .accurate
        detail.recognitionLanguages = ["en-US"]
        detail.usesLanguageCorrection = false
        let region = CGRect(x: 0, y: 0, width: 0.5, height: 0.45)
        detail.regionOfInterest = region
        try handler.perform([detail])
        recognized += (detail.results ?? []).filter { $0.topCandidates(1).first?.string == "OK" }.map { ($0, region) }
    }
    let tsv = CommandLine.arguments.contains("tsv")
    var width = 1.0
    var height = 1.0
    if tsv {
        guard let image = CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
              let w = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let h = properties[kCGImagePropertyPixelHeight] as? NSNumber else { exit(1) }
        width = w.doubleValue
        height = h.doubleValue
        print("level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext")
    }
    var index = 0
    for (observation, region) in recognized {
        if let candidate = observation.topCandidates(1).first {
            index += 1
            if tsv {
                var wordIndex = 0
                let text = candidate.string
                text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { word, range, _, _ in
                    guard let word = word,
                          let rectangle = try? candidate.boundingBox(for: range) else { return }
                    wordIndex += 1
                    let local = rectangle.boundingBox
                    let box = CGRect(x: region.minX + local.minX * region.width,
                                     y: region.minY + local.minY * region.height,
                                     width: local.width * region.width, height: local.height * region.height)
                    print("5\t1\t1\t1\t\(index)\t\(wordIndex)\t\(Int(box.minX * width))\t\(Int((1 - box.maxY) * height))\t\(Int(box.width * width))\t\(Int(box.height * height))\t\(candidate.confidence * 100)\t\(word)")
                }
            } else {
                print(candidate.string)
            }
        }
    }
} catch {
    fputs("Screenshot OCR failed: \(error)\n", stderr)
    exit(1)
}
