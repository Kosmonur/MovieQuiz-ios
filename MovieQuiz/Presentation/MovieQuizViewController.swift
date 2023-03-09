import UIKit

final class MovieQuizViewController: UIViewController {
    
    /// Структура что отображаем - для состояния "Вопрос задан"
    private struct QuizStepViewModel {
        let image: UIImage
        let question: String
        let questionNumber: String
    }
    
    /// Структура что отображаем - для состояния "Результат квиза"
    private struct QuizResultsViewModel {
        let title: String
        let text: String
        let buttonText: String
    }
    
    /// Структура с названием картинки, вопросом и верным ответом
    private struct QuizQuestion {
        let image: String
        let text: String
        let correctAnswer: Bool
    }
    
    //  Mock-данные
    private let questions: [QuizQuestion] = [
        QuizQuestion(
            image: "The Godfather",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Dark Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Kill Bill",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Avengers",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Deadpool",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Green Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Old",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "The Ice Age Adventures of Buck Wild",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Tesla",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Vivarium",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false)
    ]
    
    private var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    private var numberOfQuiz: Int = 1
    // суммарное количество верных ответов во всех играх (для расчета средней точнности)
    private var sumCorrectAnswers: Int = 0
    // лучшее количество верных ответов в сессии игр (рекорд)
    private var recordAnswers: Int = 0
    // дата установления рекорда
    private var recordDate = ""
    // флаг запрета повторного вызова функции показа ответов и изменения счетчика во время паузы
    private var showAnswerBlock = false
      
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
        
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        show(quiz: convert(model: questions[currentQuestionIndex]))
    }
    
    private func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
            UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
        }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        showAnswerResult(isCorrect: !questions[currentQuestionIndex].correctAnswer)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        showAnswerResult(isCorrect: questions[currentQuestionIndex].correctAnswer)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(imageLiteralResourceName: model.image),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questions.count)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text =  step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if showAnswerBlock {
            return
        }
        
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            notify(.success)
            correctAnswers += 1
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
            notify(.error)
        }
        
        // запрещаем повторный вызов функции показа ответа во время паузы
        showAnswerBlock = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // разрешаем вызов показа ответов после окончания паузы
            self.showAnswerBlock = false
            // переходим к выводу след вопроса или результатов
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 {
            
            // вычисляем среднюю точность в %
            sumCorrectAnswers += correctAnswers
            let accuracy = 100 * Float(sumCorrectAnswers) / Float(questions.count * numberOfQuiz)
            let accuracyString = String(format: "%.2f", accuracy)
            
            // если установлен рекорд - то сохраняем счетчик и дату
            if correctAnswers > recordAnswers {
                recordAnswers = correctAnswers
                recordDate = Date().dateTimeString
            }
            
            let text = "Ваш результат: \(correctAnswers)/\(questions.count)\nКоличество сыгранных квизов: \(numberOfQuiz)\nРекорд: \(recordAnswers)/\(questions.count) (\(recordDate))\nСредняя точность: \(accuracyString)%"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Cыграть ещё раз")
            show(quiz: viewModel)
            
        } else {
              currentQuestionIndex += 1
              show(quiz: convert(model: questions[currentQuestionIndex])) // показываем следующий вопрос
          }
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert)

        let action = UIAlertAction(
            title: result.buttonText,
            style: .default) { _ in
                self.correctAnswers = 0
                self.numberOfQuiz += 1
                self.currentQuestionIndex = 0
                self.show(quiz: self.convert(model: self.questions[self.currentQuestionIndex]))
            }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}
