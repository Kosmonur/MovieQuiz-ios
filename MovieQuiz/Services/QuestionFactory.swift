import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    private var movies: [MostPopularMovie] = []
    // массив индексов для исключения повторов фильмов
    private var arrayQuestionIndex: [Int] = []
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            
            // заполняем массив индексов
            if arrayQuestionIndex.isEmpty {
                arrayQuestionIndex = Array (0..<self.movies.count)
            }
            
            // выбираем случайный индекс
            let index = arrayQuestionIndex.randomElement() ?? 0
            
            // удаляем из массива выбранный индекс, чтобы не было повтора
            arrayQuestionIndex = arrayQuestionIndex.filter {$0 != index}
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
                }
            catch {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailToLoadImage()
                }
                return
            }
            
            let rating = Float(movie.rating) ?? 0
            
            // находим минимальный и максимальный рейтинг всех фильмов
            let ratingArray = self.movies.compactMap({Float($0.rating)})
            let minRating = ratingArray.min() ?? 0
            let maxRating = ratingArray.max() ?? 10
            
            // предлагаем сравнить рейтинг фильма только с рейтингом из диапазона от мин до макс
            let ratingForQuestion = (Int(minRating)...Int(maxRating)).randomElement() ?? 5
            
            // случайным образом генерируем вопрос - "больше чем" или "меньше чем"
            let moreThan = Bool.random()
            var correctAnswer: Bool
            
            var text = "Рейтинг этого фильма "
            if moreThan {
                text += "больше чем \(ratingForQuestion) ?"
                correctAnswer = rating > Float (ratingForQuestion)
            } else {
                text += "меньше чем \(ratingForQuestion) ?"
                correctAnswer = rating < Float (ratingForQuestion)
            }
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
}

