import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {

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
    
    private var correctAnswers: Int = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter: AlertPresenterProtocol?
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService = StatisticServiceImplementation()
    private let presenter = MovieQuizPresenter()
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // делаем статусбар светлым, как в макете
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.viewController = self
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        alertPresenter = AlertPresenter(alertController: self)

        activityIndicator.startAnimating()
        questionFactory?.loadData()
        activityIndicator.stopAnimating()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
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
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text =  step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func showAnswerResult(isCorrect: Bool) {
        
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
        if presenter.isLastQuestion() {
            
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            
            let text = """
Ваш результат: \(correctAnswers)/\(presenter.questionsAmount))
Количество сыгранных квизов: \(statisticService.gamesCount)
Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
"""
            
            let viewModel = QuizResultsViewModel(
                title: Constants.ResultsAlert.title,
                text: text,
                buttonText: Constants.ResultsAlert.buttonText)
            show(quiz: viewModel)
            
        } else {
            presenter.switchToNextQuestion()
            activityIndicator.startAnimating()
            questionFactory?.requestNextQuestion()
            activityIndicator.stopAnimating()
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
            //self.currentQuestionIndex = 0
            presenter.resetQuestionIndex()
            activityIndicator.startAnimating()
            self.questionFactory?.requestNextQuestion()
            activityIndicator.stopAnimating()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }

    
    private func showNetworkError(message: String) {
        activityIndicator.stopAnimating()
        let alertModel = AlertModel (
            title: Constants.ErrorAlert.title,
            message: message,
            buttonText: Constants.ErrorAlert.buttonText)
        {[weak self] in
            guard let self else { return }
            self.correctAnswers = 0
            //self.currentQuestionIndex = 0
            presenter.resetQuestionIndex()
            activityIndicator.startAnimating()
            self.questionFactory?.loadData()
            activityIndicator.stopAnimating()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func didLoadDataFromServer() {
        activityIndicator.startAnimating()
        questionFactory?.requestNextQuestion()
        activityIndicator.stopAnimating()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    func didFailToLoadImage() {
        activityIndicator.stopAnimating()
        let alertModel = AlertModel (
            title: Constants.ErrorAlert.title,
            message: "Картинка не загружается",
            buttonText: Constants.ErrorAlert.buttonText)
        {[weak self] in
            guard let self else { return }
            activityIndicator.startAnimating()
            self.questionFactory?.requestNextQuestion()
            activityIndicator.stopAnimating()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
}
