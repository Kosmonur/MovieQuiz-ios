import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private enum Constants {
        enum ResultsAlert {
            static let title = "Этот раунд окончен!"
            static let buttonText = "Cыграть ещё раз"
        }
        enum ErrorAlert {
            static let title = "Что-то пошло не так("
            static let buttonText = "Попробовать ещё раз"
        }
    }
    
    let questionsAmount = 10
    
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    private var currentQuestionIndex = 0
    var currentQuestion: QuizQuestion?
    private weak var viewController: MovieQuizViewController?
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        viewController.showLoadingIndicator()
        questionFactory?.loadData()
        viewController.hideLoadingIndicator()
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
        viewController?.hideLoadingIndicator()
        let alertModel = AlertModel (
            title: Constants.ErrorAlert.title,
            message: "Картинка не загружается",
            buttonText: Constants.ErrorAlert.buttonText)
        {[weak self] in
            guard let self else { return }
            viewController?.showLoadingIndicator()
            self.questionFactory?.requestNextQuestion()
            viewController?.hideLoadingIndicator()
        }
        viewController?.alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            
            statisticService.store(correct: correctAnswers, total: self.questionsAmount)
            
            let text = """
Ваш результат: \(correctAnswers)/\(self.questionsAmount))
Количество сыгранных квизов: \(statisticService.gamesCount)
Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
"""
            
            let viewModel = QuizResultsViewModel(
                title: Constants.ResultsAlert.title,
                text: text,
                buttonText: Constants.ResultsAlert.buttonText)
            viewController?.show(quiz: viewModel)
            
        } else {
            self.switchToNextQuestion()
            viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion()
            viewController?.hideLoadingIndicator()
        }
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion else { return }
        viewController?.showAnswerResult(isCorrect: currentQuestion.correctAnswer == isYes)
        }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        viewController?.showLoadingIndicator()
        questionFactory?.requestNextQuestion()
        viewController?.hideLoadingIndicator()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func didAnswerCorrect () {
            correctAnswers += 1
    }

}
