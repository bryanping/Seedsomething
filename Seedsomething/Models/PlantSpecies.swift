//
//  PlantSpecies.swift
//  Seedsomething
//
//  Created by AI Agent.
//

import Foundation

/// 植物种类枚举（50种）
enum PlantSpecies: String, CaseIterable, Codable, Identifiable {

    // MARK: - singleBlade 单叶直立型
    case wheat = "小麦"
    case corn = "玉米"
    case rice = "稻苗"
    case chives = "韭菜"
    case foxtailGrass = "狗尾草"

    // MARK: - classicSprout 双子叶对称型
    case mungBeanSprout = "绿豆芽"
    case beanSprout = "豆苗"
    case alfalfa = "苜蓿"
    case sesameSeedling = "芝麻苗"
    case bokChoy = "小白菜"
    case kale = "羽衣甘蓝"
    case taro = "芋头"
    case sunflowerSeedling = "向日葵幼苗"
    case sunflower = "向日葵"
    case morningGlory = "牵牛花"
    case tulipBud = "郁金香花苞"
    case marigold = "金盏花"
    case camelliaBud = "茶花花苞"
    case eveningPrimrose = "夜来香"
    case blueStarFlower = "蓝星花"
    case bluePoppy = "蓝色罂粟"

    // MARK: - succulent 肉质厚叶型
    case succulent = "多肉植物"
    case cactus = "仙人掌"

    // MARK: - leafCluster 多叶簇生型
    case clover = "三叶草"
    case fourLeafClover = "四叶草"
    case purpleOxalis = "紫叶酢浆草"
    case silverDust = "银叶菊"
    case moss = "苔藓"
    case cyclamen = "仙客来"
    case coleus = "彩叶草"
    case rainbowDaisy = "彩虹菊"

    // MARK: - palmUmbrella 细柄伞状型
    case sweetgum = "枫香"
    case daphne = "瑞香"
    case rubberTree = "橡皮树"
    case cherryBlossomBud = "樱花花芽"
    case ginkgo = "银杏"
    case maple = "枫树"
    case banyan = "榕树"
    case camphor = "樟树"
    case olive = "橄榄树"
    case willow = "柳树嫩叶"
    case pine = "松树"
    case autumnMaple = "枫叶（秋季）"
    case bay = "月桂"
    case rosemary = "迷迭香"
    case ivy = "常春藤"
    case rainbowEucalyptus = "彩虹尤加利"

    // MARK: - fernCurl 蕨类展开型
    case fern = "蕨类植物"
    case pothos = "绿萝"
    case peaceLily = "白掌"

    var id: String { rawValue }

    /// 植物显示名称
    var displayName: String {
        return rawValue
    }

    /// 植物分类
    var category: PlantCategory {
        switch self {
        case .mungBeanSprout, .beanSprout, .alfalfa, .sesameSeedling:
            return .beans
        case .bokChoy, .chives, .kale, .taro:
            return .vegetables
        case .pothos, .clover, .fourLeafClover, .fern, .rubberTree, .succulent, .purpleOxalis,
            .silverDust, .moss, .foxtailGrass, .cyclamen, .ivy, .cactus, .coleus,
            .rainbowEucalyptus, .rainbowDaisy, .bluePoppy:
            return .ornamental
        case .sweetgum, .daphne, .cherryBlossomBud, .ginkgo, .maple, .banyan, .camphor, .olive,
            .willow, .pine, .autumnMaple:
            return .trees
        case .morningGlory, .tulipBud, .marigold, .camelliaBud, .eveningPrimrose, .peaceLily,
            .blueStarFlower, .sunflowerSeedling, .sunflower:
            return .flowers
        case .wheat, .corn, .rice:
            return .crops
        case .bay, .rosemary:
            return .herbs
        }
    }

    /// 稀有度（用于随机生成）
    var rarity: PlantRarity {
        switch self {
        case .fourLeafClover, .rainbowEucalyptus, .rainbowDaisy, .bluePoppy, .autumnMaple:
            return .rare
        case .cherryBlossomBud, .ginkgo, .olive, .pine, .camelliaBud:
            return .uncommon
        default:
            return .common
        }
    }

    /// 获取植物图片文件名（根据生长阶段和变异等级）
    /// - Parameters:
    ///   - stage: 生长阶段 (1-5)
    ///   - mutationLevel: 变异等级 (0-4)
    /// - Returns: 图片文件名
    func imageName(for stage: Int, mutationLevel: Int = 0) -> String {
        let stage = min(max(stage, 1), 5)

        // 如果该植物有特定资源，直接使用自己的资源
        if hasSpecificAsset {
            // 变异后缀
            let mutationSuffix = mutationLevel > 0 ? "_rare" : ""
            return
                "plant_\(String(format: "%02d", assetId))_\(assetNamePart)_v\(stage)\(mutationSuffix)"
        } else {
            // 如果没有特定资源，使用其幼苗类型对应的代表植物的资源（全阶段通用）
            // 这样所有植物都能享受到高清手绘风格，避免显示低质量资源
            return seedlingType.representativeSpecies.imageName(for: stage, mutationLevel: 0)  // 代理植物暂不用变异图
        }
    }

    /// 获取变异后的显示名称
    /// - Parameter level: 变异等级 (1-4)
    /// - Returns: 变异名称
    func mutationName(for level: Int) -> String {
        switch (self, level) {
        // Lv.1 微稀有
        case (.clover, 1): return "四叶草"
        case (.beanSprout, 1): return "双茎豆苗"
        case (.wheat, 1): return "金穗小麦"
        case (.rice, 1): return "弯月稻穗"

        // Lv.2 稀有
        case (.alfalfa, 2): return "星形苜蓿"
        case (.sunflower, 2): return "双花向日葵"
        case (.coleus, 2): return "彩纹彩叶"
        case (.rosemary, 2): return "环枝迷迭香"

        // Lv.3 超稀有
        case (.cherryBlossomBud, 3): return "永不凋零花芽"
        case (.blueStarFlower, 3): return "星辉花"
        case (.maple, 3): return "渐变霜枫"
        case (.rainbowDaisy, 3): return "光谱菊"

        // Lv.4 传说级
        case (.clover, 4): return "五叶草"
        case (.moss, 4): return "夜光苔"
        case (.pine, 4): return "星纹松"
        case (.ginkgo, 4): return "时序银杏"

        default:
            return "稀有\(rawValue)"
        }
    }

    /// 标记目前哪些植物已经拥有了特定的高清资源（8种已处理）
    private var hasSpecificAsset: Bool {
        switch self {
        case .clover,  // ID 10 三叶草
            .fern,  // ID 12 蕨类植物
            .cactus,  // ID 28 仙人掌
            .maple,  // ID 37 枫树
            .willow,  // ID 41 柳树嫩叶
            .pine,  // ID 42 松树
            .sunflower,  // ID 45 向日葵
            .rosemary:  // ID 50 迷迭香
            return true
        default:
            return false
        }
    }

    /// 根据等级获取生长阶段
    /// - Parameter level: 草的等级
    /// - Returns: 生长阶段 (1-5)
    static func growthStage(for level: Int) -> Int {
        switch level {
        case 1...2: return 1  // 幼苗 (统一形态)
        case 3...5: return 2  // 成长 (开始分化)
        case 6...10: return 3  // 成熟
        case 11...20: return 4  // 繁茂
        default: return 5  // 完全体
        }
    }

    /// 幼苗类型（6种统一形态）
    enum SeedlingType {
        case singleBlade  // ① 单叶直立型 (如：小麦、玉米、水稻)
        case classicSprout  // ② 双子叶对称型 (如：豆类、大部分蔬菜、向日葵)
        case succulent  // ③ 肉质厚叶型 (如：多肉、芦荟)
        case leafCluster  // ④ 多叶簇生型 (如：三叶草、草莓、大部分花卉)
        case palmUmbrella  // ⑤ 细柄伞状型 (如：树木幼苗、枫树)
        case fernCurl  // ⑥ 蕨类展开型 (如：蕨类、含羞草)

        /// 該類型對應的擁有高清資源的代表植物
        var representativeSpecies: PlantSpecies {
            switch self {
            case .singleBlade: return .willow
            case .classicSprout: return .sunflower
            case .succulent: return .cactus
            case .leafCluster: return .clover
            case .palmUmbrella: return .maple
            case .fernCurl: return .fern
            }
        }

        // 舊的屬性保留以防相容性，但現在直接導向代表植物
        var templateImageName: String {
            return representativeSpecies.imageName(for: 1)
        }
    }

    /// 植物对应的幼苗类型
    var seedlingType: SeedlingType {
        switch self {
        // ① 单叶直立型
        case .wheat, .corn, .rice, .foxtailGrass, .tulipBud:
            return .singleBlade

        // ③ 肉质厚叶型
        case .succulent, .cactus:
            return .succulent

        // ⑤ 细柄伞状型 (树木类)
        case .sweetgum, .ginkgo, .maple, .banyan, .camphor, .olive, .willow, .pine, .autumnMaple,
            .cherryBlossomBud, .rubberTree, .rainbowEucalyptus:
            return .palmUmbrella

        // ⑥ 蕨类展开型
        case .fern, .moss:
            return .fernCurl

        // ④ 多叶簇生型 (花卉、草本)
        case .clover, .fourLeafClover, .purpleOxalis, .marigold, .camelliaBud, .eveningPrimrose,
            .peaceLily, .blueStarFlower, .silverDust, .cyclamen, .ivy, .coleus, .rainbowDaisy,
            .bluePoppy, .chives, .daphne, .rosemary, .bay, .pothos:
            return .leafCluster

        // ② 双子叶对称型 (默认)
        default:
            return .classicSprout
        }
    }

    /// 映射到資產資料夾中的 01-50 編號
    var assetId: Int {
        switch self {
        case .mungBeanSprout: return 1
        case .beanSprout: return 2
        case .alfalfa: return 3
        case .sesameSeedling: return 4
        case .bokChoy: return 5
        case .chives: return 6
        case .kale: return 7
        case .taro: return 8
        case .pothos: return 9
        case .clover: return 10
        case .fourLeafClover: return 11
        case .fern: return 12
        case .rubberTree: return 13
        case .morningGlory: return 14
        case .tulipBud: return 15
        case .marigold: return 16
        case .camelliaBud: return 17
        case .eveningPrimrose: return 18
        case .peaceLily: return 19
        case .succulent: return 20
        case .purpleOxalis: return 21
        case .blueStarFlower: return 22
        case .silverDust: return 23
        case .moss: return 24
        case .foxtailGrass: return 25
        case .cyclamen: return 26
        case .ivy: return 27
        case .cactus: return 28
        case .coleus: return 29
        case .rainbowEucalyptus: return 30
        case .rainbowDaisy: return 31
        case .bluePoppy: return 32
        case .sweetgum: return 33
        case .daphne: return 34
        case .cherryBlossomBud: return 35
        case .ginkgo: return 36
        case .maple: return 37
        case .banyan: return 38
        case .camphor: return 39
        case .olive: return 40
        case .willow: return 41
        case .pine: return 42
        case .autumnMaple: return 43
        case .sunflowerSeedling: return 44
        case .sunflower: return 45
        case .wheat: return 46
        case .corn: return 47
        case .rice: return 48
        case .bay: return 49
        case .rosemary: return 50
        }
    }

    /// 映射到檔案名稱中的名稱部分（如「小麦」映射到「小麦苗」）
    var assetNamePart: String {
        switch self {
        case .beanSprout: return "豆苗"
        case .chives: return "韭菜"
        case .wheat: return "小麦苗"
        case .corn: return "玉米苗"
        default: return rawValue
        }
    }
}

/// 植物分类
enum PlantCategory: String, Codable {
    case beans = "豆类"
    case vegetables = "蔬菜"
    case ornamental = "观赏植物"
    case trees = "树木"
    case flowers = "花卉"
    case crops = "作物"
    case herbs = "香草"

    var displayName: String {
        return rawValue
    }
}

/// 植物稀有度
enum PlantRarity: Int, Codable {
    case common = 1  // 常见 (70%)
    case uncommon = 2  // 不常见 (25%)
    case rare = 3  // 稀有 (5%)

    var weight: Int {
        switch self {
        case .common: return 70
        case .uncommon: return 25
        case .rare: return 5
        }
    }
}

/// 植物随机生成器
struct PlantRandomizer {
    /// 根据稀有度权重随机生成植物
    static func randomPlant() -> PlantSpecies {
        let allPlants = PlantSpecies.allCases
        var weightedPlants: [PlantSpecies] = []

        for plant in allPlants {
            let weight = plant.rarity.weight
            weightedPlants.append(contentsOf: Array(repeating: plant, count: weight))
        }

        return weightedPlants.randomElement() ?? .mungBeanSprout
    }

    /// 根据用户ID生成确定性随机植物（相同用户ID总是得到相同植物）
    static func deterministicPlant(for userId: String) -> PlantSpecies {
        let hash = userId.hashValue
        let index = abs(hash) % PlantSpecies.allCases.count
        return PlantSpecies.allCases[index]
    }

    /// 获取初始随机种子（从Common中随机选1个）
    static func randomStarterSeed() -> PlantSpecies {
        let commonPlants = PlantSpecies.allCases.filter { $0.rarity == .common }
        return commonPlants.randomElement() ?? .mungBeanSprout
    }
}
