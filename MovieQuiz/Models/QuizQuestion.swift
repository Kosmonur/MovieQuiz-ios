import Foundation

/// Структура с названием картинки, вопросом и верным ответом
struct QuizQuestion {
    let image: Data
    let text: String
    let correctAnswer: Bool
}
