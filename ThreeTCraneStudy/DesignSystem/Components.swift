import SwiftUI
import UIKit

extension View {
    func brandCard(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.craneBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

struct BundledQuestionImage: View {
    let resourceName: String
    let accessibilityLabel: String
    var maxHeight: CGFloat = 240

    private var image: UIImage? {
        guard let resourceRoot = Bundle.main.resourceURL else { return nil }
        let url = resourceRoot
            .appendingPathComponent("QuestionBankAssets", isDirectory: true)
            .appendingPathComponent(resourceName)
        return UIImage(contentsOfFile: url.path)
    }

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .accessibilityLabel(accessibilityLabel)
        } else {
            Label("題目圖示無法載入", systemImage: "photo.badge.exclamationmark")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, minHeight: 80)
                .accessibilityLabel("\(accessibilityLabel)，圖示無法載入")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.craneBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.cranePrimaryBlue)
                .frame(width: 44, height: 44)
                .background(Color.cranePrimaryBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 56)
    }
}

struct BrandSectionTitle: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.craneNeutralDark)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

struct BrandShortcutTile: View {
    let title: String
    let assetName: String

    var body: some View {
        VStack(spacing: 8) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.craneNeutralDark)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct BrandProgressRing: View {
    let value: Double
    let centerText: String
    var subtitle: String = ""
    var color: Color = .cranePrimaryBlue

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(centerText)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Color.craneNeutralDark)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BrandProgressRow: View {
    let title: String
    let value: Double
    let valueText: String
    var color: Color = .cranePrimaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(valueText)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * min(max(value, 0), 1))
                }
            }
            .frame(height: 7)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CraneHeroHeader: View {
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [.cranePrimaryBlue, .craneSupportBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("三噸以上固定式起重機")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("考照學習系統")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.96))
                    Text("題庫・解析・錯題・模擬測驗")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.86))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CraneLineIllustration()
                    .frame(width: 125, height: 118)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 162)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .accessibilityElement(children: .combine)
    }
}

private struct CraneLineIllustration: View {
    var body: some View {
        Canvas { context, size in
            let yellow = Color(red: 1.0, green: 0.78, blue: 0.16)
            var mast = Path()
            mast.move(to: CGPoint(x: size.width * 0.72, y: size.height * 0.88))
            mast.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.17))
            context.stroke(mast, with: .color(yellow), lineWidth: 7)

            var boom = Path()
            boom.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.23))
            boom.addLine(to: CGPoint(x: size.width * 0.94, y: size.height * 0.23))
            context.stroke(boom, with: .color(yellow), lineWidth: 6)

            var brace = Path()
            brace.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.23))
            brace.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.56))
            brace.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.23))
            brace.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.43))
            context.stroke(brace, with: .color(.white.opacity(0.86)), lineWidth: 2)

            var cable = Path()
            cable.move(to: CGPoint(x: size.width * 0.29, y: size.height * 0.23))
            cable.addLine(to: CGPoint(x: size.width * 0.29, y: size.height * 0.72))
            context.stroke(cable, with: .color(.white), lineWidth: 2)

            let hook = CGRect(x: size.width * 0.23, y: size.height * 0.68, width: 15, height: 20)
            context.stroke(Path(ellipseIn: hook), with: .color(yellow), lineWidth: 4)

            var base = Path()
            base.move(to: CGPoint(x: size.width * 0.58, y: size.height * 0.90))
            base.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.90))
            context.stroke(base, with: .color(yellow), lineWidth: 8)
        }
    }
}
