import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    private var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService = StatisticServiceImplementation()

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    
    // делаем статусбар светлым, как в макете
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
                self?.show(quiz: viewModel)
        }
    }
    
    private func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion else { return }
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
        
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            notify(.success)
            correctAnswers += 1
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
            notify(.error)
        }
        
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self else { return }

            self.showNextQuestionOrResults()
            self.noButton.isEnabled = true
            self.yesButton.isEnabled = true
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let text = "Ваш результат: \(correctAnswers)/\(questionsAmount)\nКоличество сыгранных квизов: \(statisticService.gamesCount)\nРекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))\nСредняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Cыграть ещё раз")
            show(quiz: viewModel)
            
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
        
        private func show(quiz result: QuizResultsViewModel) {
            let alertModel = AlertModel (
                title: result.title,
                message: result.text,
                buttonText: result.buttonText)
                {[weak self] in
                    guard let self else { return }
                    self.correctAnswers = 0
                    self.currentQuestionIndex = 0
                    self.questionFactory?.requestNextQuestion()
                }
            let alertPresenter = AlertPresenter()
            alertPresenter.showAlert(alertController: self, alertModel: alertModel)
        }
}
