import Foundation

protocol StatisticService {
    func store(correct count: Int, total amount: Int)
    var totalAccuracy: Double { get }
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
}

struct GameRecord: Codable, Comparable {
    let correct: Int
    let total: Int
    let date: Date
    static func < (lhs: GameRecord, rhs: GameRecord) -> Bool {
        return lhs.correct < rhs.correct
    }
}

final class StatisticServiceImplementation: StatisticService {
    private enum Keys: String {
        case correct, total, bestGame, gamesCount
    }
    private let userDefaults = UserDefaults.standard
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date())
            }
            return record
        }
        
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    var gamesCount: Int {
        get {
            userDefaults.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var totalAccuracy: Double {
        get{
            let correctAnswer = userDefaults.integer(forKey: Keys.correct.rawValue)
            let totalAmount = userDefaults.integer(forKey: Keys.total.rawValue)
            return totalAmount != 0 ? 100 * Double(correctAnswer) / Double(totalAmount) : 0
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        
        var correctAnswer = userDefaults.integer(forKey: Keys.correct.rawValue)
        correctAnswer += count
        userDefaults.set(correctAnswer,forKey: Keys.correct.rawValue)
        
        var totalAmount = userDefaults.integer(forKey: Keys.total.rawValue)
        totalAmount += amount
        userDefaults.set(totalAmount,forKey: Keys.total.rawValue)
        
        gamesCount += 1
        
        let currentGame = GameRecord(correct: count, total: amount, date: Date())
        if bestGame < currentGame {
            bestGame = currentGame
        }
    }
}

