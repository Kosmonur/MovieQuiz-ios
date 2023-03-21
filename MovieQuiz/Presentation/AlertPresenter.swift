import UIKit

class AlertPresenter {
    func showAlert(alertController: UIViewController, alertModel: AlertModel) {
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: alertModel.buttonText,
            style: .default) { _ in alertModel.completion() }
        alert.addAction(action)
        alertController.present(alert, animated: true, completion: nil)
    }
}
