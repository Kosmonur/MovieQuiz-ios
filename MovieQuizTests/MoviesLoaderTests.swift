import Foundation
import XCTest
@testable import MovieQuiz

class StubNetworkClient: NetworkRouting {
    
    enum TestError: Error { // тестовая ошибка
    case test
    }
    
    let emulateError: Bool // заглушка эмуляции ошибки сети
    
    init (emulateError: Bool){
        self.emulateError = emulateError
    }
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        if emulateError {
            handler(.failure(TestError.test))
        } else {
            handler(.success(expectedResponse))
        }
    }
    
    private var expectedResponse: Data {
        """
        {
           "errorMessage" : "",
           "items" : [
              {
                 "crew" : "Frank Darabont (dir.), Tim Robbins, Morgan Freeman",
                 "fullTitle" : "The Shawshank Redemption (1994)",
                 "id" : "tt0111161",
                 "imDbRating" : "9.2",
                 "imDbRatingCount" : "2723406",
                 "image" : "https://m.media-amazon.com/images/M/MV5BNDE3ODcxYzMtY2YzZC00NmNlLWJiNDMtZDViZWM2MzIxZDYwXkEyXkFqcGdeQXVyNjAwNDUxODI@._V1_UX128_CR0,12,128,176_AL_.jpg",
                 "rank" : "1",
                 "title" : "The Shawshank Redemption",
                 "year" : "1994"
              },
              {
                 "crew" : "Francis Ford Coppola (dir.), Marlon Brando, Al Pacino",
                 "fullTitle" : "The Godfather (1972)",
                 "id" : "tt0068646",
                 "imDbRating" : "9.2",
                 "imDbRatingCount" : "1892959",
                 "image" : "https://m.media-amazon.com/images/M/MV5BM2MyNjYxNmUtYTAwNi00MTYxLWJmNWYtYzZlODY3ZTk3OTFlXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_UX128_CR0,12,128,176_AL_.jpg",
                 "rank" : "2",
                 "title" : "The Godfather",
                 "year" : "1972"
              }
            ]
          }
        """.data(using: .utf8) ?? Data()
    }
}

class MoviesLoaderTests: XCTestCase {
    func testSuccessLoading() throws {
        // Given
        let stubNetworkClient = StubNetworkClient(emulateError: false) // не эмулируем ошибку
        let loader = MoviesLoader(networkClient: stubNetworkClient)
        
        // When
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies {result in
            // Then
            switch result {
            case .success(let movies):
                // сравниваем что пришло два фильма
                XCTAssertEqual(movies.items.count, 2)
                expectation.fulfill()
            case .failure(_):
                XCTFail("Unexpected failure")
            }
        }
        
        waitForExpectations(timeout: 1)
        
    }
    
    func testFailureLoading() throws {
        // Given
        let stubNetworkClient = StubNetworkClient(emulateError: true) // эмулируем ошибку
        let loader = MoviesLoader(networkClient: stubNetworkClient)
        
        // When
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies {result in
            // Then
            switch result {
            case .success(_):
                XCTFail("Unexpected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1)
        
    }
    
}
