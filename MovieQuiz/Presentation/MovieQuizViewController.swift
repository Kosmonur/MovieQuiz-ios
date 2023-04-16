import UIKit

final class MovieQuizViewController: UIViewController {
    
    private enum ConstantsAlertMessage {
            static let title = "Что-то пошло не так("
            static let buttonText = "Попробовать ещё раз"
    }
    
    private var questionFactory: QuestionFactoryProtocol?
    var alertPresenter: AlertPresenterProtocol?
    private var presenter: MovieQuizPresenter!
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = AlertPresenter(alertController: self)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    private func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text =  step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func showAnswerResult(isCorrect: Bool) {
        
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            notify(.success)
            presenter.didAnswerCorrect()
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
            notify(.error)
        }
        
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {[weak self] in
            guard let self else { return }
            
            self.presenter.showNextQuestionOrResults()
            self.noButton.isEnabled = true
            self.yesButton.isEnabled = true
        }
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel (
            title: result.title,
            message: result.text,
            buttonText: result.buttonText)
        {[weak self] in
            guard let self else { return }
            self.presenter.restartGame()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        let alertModel = AlertModel (
            title: ConstantsAlertMessage.title,
            message: message,
            buttonText: ConstantsAlertMessage.buttonText)
        {[weak self] in
            guard let self else { return }
            self.presenter.restartGame()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
}
