import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    private enum ErrorMessage {
            static let title = "Что-то пошло не так("
            static let buttonText = "Попробовать ещё раз"
            static let messageImageError = "Картинка не загружается"
    }

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    
    private var presenter: MovieQuizPresenter!
    var alertPresenter: AlertPresenterProtocol?
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = AlertPresenter(alertController: self)
    }
    
    // MARK: - Actions
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    // MARK: - Private functions
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text =  step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderColor = UIColor.clear.cgColor
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
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            notify(.success)
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
            notify(.error)
        }
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }

    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
    
    func lockButtons() {
        noButton.isEnabled = false
        yesButton.isEnabled = false
    }
    
    func unlockButtons() {
        noButton.isEnabled = true
        yesButton.isEnabled = true
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        let alertModel = AlertModel (
            title: ErrorMessage.title,
            message: message,
            buttonText: ErrorMessage.buttonText)
        {[weak self] in
            guard let self else { return }
            self.presenter.reloadData()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    
    func showLoadImageError() {
        hideLoadingIndicator()
        let alertModel = AlertModel (
            title: ErrorMessage.title,
            message: ErrorMessage.messageImageError,
            buttonText: ErrorMessage.buttonText)
        {[weak self] in
            guard let self else { return }
            self.presenter.didLoadDataFromServer()
        }
        alertPresenter?.showAlert(alertModel: alertModel)
    }
    

}
