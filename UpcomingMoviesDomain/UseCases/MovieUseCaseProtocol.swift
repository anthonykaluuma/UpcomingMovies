//
//  MovieUseCaseProtocol.swift
//  UpcomingMoviesDomain
//
//  Created by Alonso on 11/3/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation

public protocol MovieUseCaseProtocol {
    
//    func getMovies(page: Int,
//                   movieListFilter: MovieListFilter,
//                   completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getUpcomingMovies(page: Int,
                           completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getPopularMovies(page: Int,
                          completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getTopRatedMovies(page: Int,
                           completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getMoviesByGenre(page: Int,
                          genreId: Int,
                          completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getSimilarMovies(page: Int,
                          movieId: Int,
                          completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getMovieDetail(for movieId: Int,
                        completion: @escaping (Result<Movie, Error>) -> Void)
    
    func searchMovies(searchText: String, includeAdult: Bool, page: Int?,
                      completion: @escaping (Result<[Movie], Error>) -> Void)
    
    func getMovieReviews(for movieId: Int, page: Int?,
                         completion: @escaping (Result<[Review], Error>) -> Void)
    
    func getMovieVideos(for movieId: Int, page: Int?,
                        completion: @escaping (Result<[Video], Error>) -> Void)
    
    func getMovieCredits(for movieId: Int, page: Int?,
                         completion: @escaping (Result<MovieCredits, Error>) -> Void)
    
    func isMovieInFavorites(for movieId: Int,
                            completion: @escaping (Result<Bool, Error>) -> Void)
    
    func isMovieInWatchList(for movieId: Int,
                            completion: @escaping (Result<Bool, Error>) -> Void)
    
}
