import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
}

extension GameRecord: Comparable {
    
    private var accuracy: Double {
        total != 0 ? 100 * Double(correct) / Double(total) : 0
    }
    
    static func < (lhs: GameRecord, rhs: GameRecord) -> Bool {
        return lhs.accuracy < rhs.accuracy
    }
}
