import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    // MARK: - Constants
    
    private enum ResultsMessage {
            static let title = "Этот раунд окончен!"
            static let buttonText = "Cыграть ещё раз"
    }
    
    private let questionsAmount = 10
    
    // MARK: - Private Properties
    
    private var statisticService: StatisticService!
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    
    private var currentQuestion: QuizQuestion?
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        statisticService = StatisticServiceImplementation()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        viewController.showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.showLoadingIndicator()
        questionFactory?.requestNextQuestion()
        viewController?.hideLoadingIndicator()
    }
    
    func didFailToLoadData(with error: Error) {
         viewController?.showNetworkError(message: error.localizedDescription)
     }
    
    func didFailToLoadImage() {
        viewController?.showLoadImageError()
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        didLoadDataFromServer()
    }
    
    func reloadData() {
        currentQuestionIndex = 0
        correctAnswers = 0
        viewController?.showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    private func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion else { return }
        proceedWithAnswer(isCorrect: currentQuestion.correctAnswer == isYes)
        }
    
    private func proceedWithAnswer(isCorrect: Bool) {
        
        if isCorrect {
            correctAnswers += 1
        }
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        viewController?.lockButtons()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self else { return }
            
            self.proceedToNextQuestionOrResults()
            viewController?.unlockButtons()
        }
    }
    
    private func proceedToNextQuestionOrResults() {
        if self.isLastQuestion() {
            
            statisticService.store(correct: correctAnswers, total: self.questionsAmount)
            
            let text = """
Ваш результат: \(correctAnswers)/\(self.questionsAmount))
Количество сыгранных квизов: \(statisticService.gamesCount)
Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
"""
            
            let viewModel = QuizResultsViewModel(
                title: ResultsMessage.title,
                text: text,
                buttonText: ResultsMessage.buttonText)
            viewController?.show(quiz: viewModel)
            
        } else {
            self.switchToNextQuestion()
            self.didLoadDataFromServer()
        }
    }
    
}
