import UIKit
import SwiftUI

enum ShareCardRenderer {
    static func render(song: String, artist: String, knobs: [String: Int], ampModel: String, confidence: Double) -> UIImage {
        let size = CGSize(width: 1080, height: 1620)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let tolex = UIColor(red: 0.11, green: 0.106, blue: 0.102, alpha: 1)
            let amber = UIColor(red: 1.0, green: 0.69, blue: 0.125, alpha: 1)
            let cream = UIColor(red: 0.96, green: 0.937, blue: 0.878, alpha: 1)

            tolex.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for x in stride(from: 0, to: 1080, by: 54) {
                for y in stride(from: 0, to: 1620, by: 54) {
                    UIColor.white.withAlphaComponent(0.02).setFill()
                    context.fill(CGRect(x: x + 2, y: y + 2, width: 48, height: 48))
                }
            }

            amber.setFill()
            context.fill(CGRect(x: 60, y: 60, width: 16, height: 16))
            "DIALED IN ✅".draw(at: CGPoint(x: 96, y: 54), withAttributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .heavy),
                .foregroundColor: amber
            ])

            drawWrapped(song, at: CGPoint(x: 60, y: 140), maxWidth: 960, font: UIFont.systemFont(ofSize: 88, weight: .black), color: cream)
            artist.draw(at: CGPoint(x: 60, y: 320), withAttributes: [
                .font: UIFont.systemFont(ofSize: 44, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ])

            var y: CGFloat = 460
            for name in AppConstants.knobOrder {
                let label = AppConstants.knobLabels[name] ?? name
                let value = knobs[name] ?? 5
                label.uppercased().draw(at: CGPoint(x: 60, y: y), withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 46, weight: .semibold),
                    .foregroundColor: cream
                ])
                let barWidth: CGFloat = 560
                UIColor.white.withAlphaComponent(0.15).setFill()
                context.fill(CGRect(x: 420, y: y + 18, width: barWidth, height: 14))
                amber.setFill()
                context.fill(CGRect(x: 420, y: y + 18, width: barWidth * CGFloat(value) / 10.0, height: 14))
                "\(value)/10".draw(at: CGPoint(x: 990, y: y), withAttributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 46, weight: .bold),
                    .foregroundColor: amber
                ])
                y += 130
            }

            ampModel.draw(at: CGPoint(x: 60, y: y + 40), withAttributes: [
                .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ])
            let confText = "Confidence \(Int(confidence * 100))%"
            confText.draw(at: CGPoint(x: 60, y: y + 110), withAttributes: [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.55)
            ])

            "Made with AmpWhisper — Your amp has secrets.".draw(at: CGPoint(x: 60, y: 1500), withAttributes: [
                .font: UIFont.systemFont(ofSize: 34, weight: .medium),
                .foregroundColor: amber
            ])
        }
    }

    private static func drawWrapped(_ text: String, at point: CGPoint, maxWidth: CGFloat, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: attributes, context: nil
        )
        (text as NSString).draw(in: CGRect(origin: point, size: CGSize(width: maxWidth, height: ceil(bounds.height))), withAttributes: attributes)
    }
}
