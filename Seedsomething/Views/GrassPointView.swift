//
//  GrassPointView.swift
//  Seedsomething
//
//  根据 waterCount 显示不同草形态（草点阶段视觉变化）
//

import SwiftUI

struct GrassPointView: View {
    let waterCount: Int
    let isZoomedOut: Bool

    /// 根据浇水次数返回形态：0 新草 → 1–3 小苗 → 4–7 成长 → 8+ 茂盛
    private var stage: GrassPointStage {
        switch waterCount {
        case 0: return .seed
        case 1...3: return .seedling
        case 4...7: return .growing
        default: return .lush
        }
    }

    var body: some View {
        if isZoomedOut {
            Circle()
                .fill(Color.brandLightGreen)
                .frame(width: 8, height: 8)
                .shadow(radius: 1)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack {
            if stage == .lush {
                Circle()
                    .fill(Color.brandLightGreen.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .blur(radius: 4)
            }
            Group {
                switch stage {
                case .seed:
                    Image(systemName: "leaf")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.brandLightGreen.opacity(0.9))
                case .seedling:
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.brandLightGreen)
                case .growing:
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.brandLightGreen)
                case .lush:
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.brandLightGreen)
                }
            }
            .shadow(radius: 2, y: 2)
        }
        .frame(width: size, height: size)
    }

    private var size: CGFloat {
        switch stage {
        case .seed: return 28
        case .seedling: return 34
        case .growing: return 40
        case .lush: return 48
        }
    }
}

private enum GrassPointStage {
    case seed, seedling, growing, lush
}

#Preview {
    HStack(spacing: 16) {
        GrassPointView(waterCount: 0, isZoomedOut: false)
        GrassPointView(waterCount: 2, isZoomedOut: false)
        GrassPointView(waterCount: 5, isZoomedOut: false)
        GrassPointView(waterCount: 10, isZoomedOut: false)
        GrassPointView(waterCount: 5, isZoomedOut: true)
    }
    .padding()
}
