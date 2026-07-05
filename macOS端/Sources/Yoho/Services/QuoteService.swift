import Foundation

struct QuoteService {
    private static let all: [(text: String, scene: QuoteScene)] = [
        // 单身-专注完成
        ("每一步都算数，每一秒都有光。", .single_focus),
        ("你认真的时候，整个世界都会为你让路。", .single_focus),
        ("孤独是成长的必修课。", .single_focus),
        ("种一棵树最好的时间是十年前，其次是现在。", .single_focus),
        ("你在三四月做的事，八九月自有答案。", .single_focus),
        ("日拱一卒，功不唐捐。", .single_focus),
        ("一个人走得快，坚持才能走得远。", .single_focus),
        ("今天的专注，是明天果实的养分。", .single_focus),
        ("心之所向，素履以往。", .single_focus),
        ("你不是在浪费时间，你是在扎根。", .single_focus),
        ("慢慢地，深深地，种出属于你的森林。", .single_focus),
        ("专注是一种温柔的力量。", .single_focus),
        ("每一次呼吸，都是靠近目标的一步。", .single_focus),
        ("不要急，不要停，你没落后，也没领先。", .single_focus),
        ("你的努力，树都记得。", .single_focus),
        ("世界上没有白走的路。", .single_focus),
        ("默默耕耘，静待花开。", .single_focus),
        ("咬定青山不放松。", .single_focus),
        ("长风破浪会有时。", .single_focus),
        ("水滴石穿，非一日之功。", .single_focus),

        // 情侣-各自专注
        ("各自努力，顶峰相见。", .couple_solo),
        ("最好的爱情是并肩成长。", .couple_solo),
        ("你在努力的时候，Ta也在加油。", .couple_solo),
        ("两棵树，同一片天空。", .couple_solo),
        ("距离让思念发酵，时间让爱更甜。", .couple_solo),
        ("爱不是相互凝望，而是一起朝同一个方向看。", .couple_solo),
        ("彼此独立，又深深相依。", .couple_solo),
        ("你的努力，是Ta的骄傲。", .couple_solo),
        ("天各一方，心在一处。", .couple_solo),
        ("今天也为你种下一颗星星。", .couple_solo),

        // 情侣-共同完成
        ("一起种下的树，终于开花结果。", .couple_together),
        ("和你一起的时光，都是甜的。", .couple_together),
        ("双向奔赴，终有回响。", .couple_together),
        ("爱是共同成长的力量。", .couple_together),
        ("我们的树，我们的故事。", .couple_together),
        ("有你陪伴，修行也变得浪漫。", .couple_together),
        ("从种子到果实，从喜欢到爱。", .couple_together),
        ("一起走过的路，都是风景。", .couple_together),
        ("两个人的坚持，双倍的幸福。", .couple_together),
        ("和你有关的都在变好。", .couple_together),

        // 树阶段跃迁
        ("破土而出，向阳而生。", .tree_stage),
        ("小芽初露，未来可期。", .tree_stage),
        ("茁壮成长，枝繁叶茂。", .tree_stage),
        ("繁花似锦，不负春光。", .tree_stage),
        ("硕果累累，丰收在望。", .tree_stage),

        // 每日启动
        ("新的一天，新的阳光。早安！", .daily_start),
        ("今天也要加油哦！", .daily_start),
        ("一日之计在于晨。开始吧！", .daily_start),
        ("你的树在等你呢。", .daily_start),
        ("每一个清晨都是重生。", .daily_start),

        // 老铁模式
        ("兄弟齐心，其利断金。", .group_buddy),
        ("姐妹们一起冲！", .group_sis),
        ("一个人可以走很快，一群人可以走很远。", .group_buddy),
    ]

    static func randomQuote(scene: QuoteScene) -> String {
        let candidates = all.filter { $0.scene == scene }.map(\.text)
        guard !candidates.isEmpty else {
            return all.first(where: { $0.scene == .single_focus })?.text ?? "继续加油！"
        }
        return candidates.randomElement()!
    }

    static func randomQuote(forMode mode: QuoteMode) -> String {
        let scene: QuoteScene = switch mode {
        case .single: .single_focus
        case .coupleSolo: .couple_solo
        case .coupleTogether: .couple_together
        }
        return randomQuote(scene: scene)
    }
}

enum QuoteScene: String {
    case single_focus
    case couple_solo
    case couple_together
    case tree_stage
    case daily_start
    case group_buddy
    case group_sis
}

enum QuoteMode {
    case single
    case coupleSolo
    case coupleTogether
}
