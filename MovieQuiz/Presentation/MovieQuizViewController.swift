import UIKit

final class MovieQuizViewController: UIViewController {
    
    private var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    
    private let questionsAmount: Int = 10
    private let questionFactory: QuestionFactory = QuestionFactory()
    private var currentQuestion: QuizQuestion?
    
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
        if let firstQuestion = questionFactory.requestNextQuestion() {
            currentQuestion = firstQuestion
            let viewModel = convert(model: firstQuestion)
            show(quiz: viewModel)
        }
    }
    
    private func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(imageLiteralResourceName: model.image),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text =  step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if showAnswerBlock { return }
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self else { return }
            // разрешаем вызов показа ответов после окончания паузы
            self.showAnswerBlock = false
            // переходим к выводу след вопроса или результатов
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            // вычисляем среднюю точность в %
            sumCorrectAnswers += correctAnswers
            let accuracy = 100 * Float(sumCorrectAnswers) / Float(questionsAmount * numberOfQuiz)
            let accuracyString = String(format: "%.2f", accuracy)
            
            // если установлен рекорд - то сохраняем счетчик и дату
            if correctAnswers > recordAnswers {
                recordAnswers = correctAnswers
                recordDate = Date().dateTimeString
            }
            
            let text = "Ваш результат: \(correctAnswers)/\(questionsAmount)\nКоличество сыгранных квизов: \(numberOfQuiz)\nРекорд: \(recordAnswers)/\(questionsAmount) (\(recordDate))\nСредняя точность: \(accuracyString)%"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Cыграть ещё раз")
            show(quiz: viewModel)
            
        } else {
            currentQuestionIndex += 1
            if let nextQuestion = questionFactory.requestNextQuestion() {
                currentQuestion = nextQuestion
                let viewModel = convert(model: nextQuestion)
                show(quiz: viewModel)
            }
        }
    }
        
        private func show(quiz result: QuizResultsViewModel) {
            let alert = UIAlertController(
                title: result.title,
                message: result.text,
                preferredStyle: .alert)
            
            let action = UIAlertAction(title: result.buttonText, style: .default) {[weak self] _ in
                guard let self else { return }
                self.correctAnswers = 0
                self.numberOfQuiz += 1
                self.currentQuestionIndex = 0
                
                if let firstQuestion = self.questionFactory.requestNextQuestion() {
                    self.currentQuestion = firstQuestion
                    let viewModel = self.convert(model: firstQuestion)
                    self.show(quiz: viewModel)
                }
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
}
