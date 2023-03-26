import UIKit

protocol AlertPresenterProtocol {
    func showAlert(alertModel: AlertModel)
}

final class AlertPresenter: AlertPresenterProtocol {
    private weak var alertController: UIViewController?
    
    init(alertController: UIViewController? = nil) {
        self.alertController = alertController
    }
    
    func showAlert(alertModel: AlertModel) {
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: alertModel.buttonText, style: .default) { _ in
            alertModel.completion()
        }
        alert.addAction(action)
        alertController?.present(alert, animated: true, completion: nil)
    }
}
