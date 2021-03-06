//
//  SavedMoviesViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 3/3/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class SavedMoviesViewModel: SavedMoviesViewModelProtocol {
    
    private let useCaseProvider: UseCaseProviderProtocol
    private let accountUseCase: AccountUseCaseProtocol
    
    private let collectionOption: ProfileCollectionOption
    
    var title: String?
    
    var startLoading: Bindable<Bool> = Bindable(false)
    var viewState: Bindable<SimpleViewState<Movie>> = Bindable(.initial)
    
    var movies: [Movie] {
        return viewState.value.currentEntities
    }
    
    var movieCells: [SavedMovieCellViewModel] {
        return movies.compactMap { SavedMovieCellViewModel($0) }
    }
    
    var needsPrefetch: Bool {
        return viewState.value.needsPrefetch
    }
    
    // MARK: - Initializers
    
    init(useCaseProvider: UseCaseProviderProtocol, collectionOption: ProfileCollectionOption) {
        self.useCaseProvider = useCaseProvider
        self.accountUseCase = self.useCaseProvider.accountUseCase()
        
        self.collectionOption = collectionOption
        self.title = collectionOption.title
    }
    
    // MARK: - Public
    
    func movie(at index: Int) -> Movie {
        return movies[index]
    }
    
    // MARK: - Networking
    
    func getCollectionList() {
        let showLoader = viewState.value.isInitialPage
        fetchCollectionList(page: viewState.value.currentPage, option: collectionOption, showLoader: showLoader)
    }
    
    func refreshCollectionList() {
        fetchCollectionList(page: 1, option: collectionOption, showLoader: false)
    }
    
    private func fetchCollectionList(page: Int, option: ProfileCollectionOption, showLoader: Bool) {
        startLoading.value = showLoader
        switch option {
        case .favorites:
            fetchFavoriteList(page: page)
        case .watchlist:
            fetchWatchList(page: page)
        }
    }
    
    private func fetchFavoriteList(page: Int) {
        accountUseCase.getFavoriteList(page: page, completion: { result in
            self.startLoading.value = false
            switch result {
            case .success(let movies):
                self.processMovieResult(movies, currentPage: self.viewState.value.currentPage)
            case .failure(let error):
                self.viewState.value = .error(error)
            }
        })
    }
    
    private func fetchWatchList(page: Int) {
        accountUseCase.getWatchList(page: page, completion: { result in
            self.startLoading.value = false
            switch result {
            case .success(let movies):
                self.processMovieResult(movies, currentPage: self.viewState.value.currentPage)
            case .failure(let error):
                self.viewState.value = .error(error)
            }
        })
    }
    
    private func processMovieResult(_ movies: [Movie], currentPage: Int) {
        var allMovies = currentPage == 1 ? [] : viewState.value.currentEntities
        allMovies.append(contentsOf: movies)
        guard !allMovies.isEmpty else {
            viewState.value = .empty
            return
        }
        if movies.isEmpty {
            viewState.value = .populated(allMovies)
        } else {
            viewState.value = .paging(allMovies, next: currentPage + 1)
        }
    }
    
}
