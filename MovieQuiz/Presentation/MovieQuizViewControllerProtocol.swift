import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
  
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    func highlightImageBorder(isCorrectAnswer: Bool)
    func hideLoadingIndicator()
    func showLoadingIndicator()
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType)
    func lockButtons()
    func unlockButtons()
    func showNetworkError(message: String)
    func showLoadImageError()
}
