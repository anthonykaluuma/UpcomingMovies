//
//  UpcomingMoviesViewController.swift
//  UpcomingMovies
//
//  Created by Alonso on 11/5/18.
//  Copyright © 2018 Alonso. All rights reserved.
//

import UIKit
import UpcomingMoviesDomain

class UpcomingMoviesViewController: UIViewController, Storyboarded, PlaceholderDisplayable, Loadable {

    @IBOutlet weak var toggleGridBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    static var storyboardName: String = "UpcomingMovies"
    
    var viewModel: UpcomingMoviesViewModelProtocol!
    weak var coordinator: UpcomingMoviesCoordinatorProtocol?
    
    private var dataSource: SimpleCollectionViewDataSource<UpcomingMovieCellViewModel>!
    private var prefetchDataSource: CollectionViewDataSourcePrefetching!
    private var displayedCellsIndexPaths = Set<IndexPath>()
    
    private var previewLayout: VerticalFlowLayout!
    private var detailLayout: VerticalFlowLayout!
    
    var loaderView: RadarView!
    
    private var isAnimatingPresentation: Bool = false
    private var presentationMode: PresentationMode = .preview {
        didSet {
            if presentationMode == .preview {
                toggleGridBarButtonItem.image = #imageLiteral(resourceName: "List")
            } else {
                toggleGridBarButtonItem.image = #imageLiteral(resourceName: "Grid")
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindables()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let selectedViewController = tabBarController?.selectedViewController,
            selectedViewController == self || selectedViewController == navigationController else {
            return
        }
        coordinator.animate(alongsideTransition: { _ in
            self.detailLayout.itemSize.width = self.collectionView.frame.width - Constants.detailCellOffset
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    // MARK: - Private
    
    private func setupUI() {
        title = Constants.Title
        setupNavigationBar()
        setupCollectionView()
        setupRefreshControl()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = Constants.NavigationItemTitle
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.registerNib(cellType: UpcomingMoviePreviewCollectionViewCell.self)
        collectionView.registerNib(cellType: UpcomingMovieDetailCollectionViewCell.self)
        setupCollectionViewLayout()
    }
    
    private func setupCollectionViewLayout() {
        let detailLayoutWidth = Double(collectionView.frame.width - Constants.detailCellOffset)
        detailLayout = VerticalFlowLayout(width: detailLayoutWidth,
                                          height: Constants.detailCellHeight)
        
        let previewLayoutWidth = Constants.previewCellHeight / UIConstants.posterAspectRatio
        previewLayout = VerticalFlowLayout(width: previewLayoutWidth, height: Constants.previewCellHeight)
        
        collectionView.collectionViewLayout = presentationMode == .preview ? previewLayout : detailLayout
    }
    
    private func setupRefreshControl() {
        collectionView.refreshControl = DefaultRefreshControl(tintColor: ColorPalette.lightBlueColor,
                                              backgroundColor: collectionView.backgroundColor,
                                              refreshHandler: { [weak self] in
                                                self?.viewModel?.refreshMovies()
        })
    }
    
    private func reloadCollectionView() {
        guard let viewModel = viewModel else { return }
        dataSource = SimpleCollectionViewDataSource.make(for: viewModel.movieCells,
                                                         presentationMode: presentationMode)
        
        prefetchDataSource = CollectionViewDataSourcePrefetching(cellCount: viewModel.movieCells.count,
                                                       needsPrefetch: viewModel.needsPrefetch,
                                                       prefetchHandler: { [weak self] in
                                                        self?.viewModel?.getMovies()
        })
        
        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = prefetchDataSource
        
        collectionView.reloadData()
        collectionView.refreshControl?.endRefreshing(with: 0.5)
    }
    
    private func updateCollectionViewLayout(_ layout: UICollectionViewLayout) {
        collectionView.collectionViewLayout.invalidateLayout()
        reloadCollectionView()
        isAnimatingPresentation = true
        collectionView.setCollectionViewLayout(layout, animated: true) { completed in
            self.isAnimatingPresentation = !completed
        }
    }
    
    /**
     * Configures the view given the current state of the view.
     */
    private func configureView(withState state: SimpleViewState<Movie>) {
        switch state {
        case .populated, .paging, .initial:
             hideDisplayedPlaceholderView()
            collectionView.backgroundView = UIView(frame: .zero)
        case .empty:
            presentEmptyView(with: "No movies to show")
        case .error(let error):
            presentRetryView(with: error.localizedDescription,
                                       errorHandler: { [weak self] in
                                        self?.viewModel?.refreshMovies()
            })
        }
    }
    
    // MARK: - Reactive Behaviour
    
    private func setupBindables() {
        viewModel?.viewState.bind({ [weak self] state in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.configureView(withState: state)
                strongSelf.reloadCollectionView()
            }
        })
        viewModel?.startLoading.bind({ [weak self] start in
            start ? self?.showLoader() : self?.hideLoader()
        })
        viewModel?.getMovies()
    }
    
    // MARK: - Actions
    
    @IBAction func toggleGridAction(_ sender: Any) {
        guard !isAnimatingPresentation else { return }
        switch presentationMode {
        case .preview:
            presentationMode = .detail
            updateCollectionViewLayout(detailLayout)
        case .detail:
            presentationMode = .preview
            updateCollectionViewLayout(previewLayout)
        }
    }
    
}

// MARK: - TabBarScrollable

extension UpcomingMoviesViewController: TabBarScrollable {
    
    func handleTabBarSelection() {
        collectionView.scrollToTop(animated: true)
    }
    
}

// MARK: - UICollectionViewDelegate

extension UpcomingMoviesViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath),
            let cell = collectionView.cellForItem(at: indexPath) as? UpcomingMovieCollectionViewCell else {
                return
        }
        
        let imageToTransition = cell.posterImageView.image
        let selectedFrame = collectionView.convert(cellAttributes.frame,
                                               to: collectionView.superview)
        
        let navigationConfiguration = NavigationConfiguration(selectedFrame: selectedFrame,
                                                              imageToTransition: imageToTransition,
                                                              transitionOffset: view.safeAreaInsets.left)
        
        coordinator?.showDetail(for: viewModel.movie(for: indexPath.row), with: navigationConfiguration)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !displayedCellsIndexPaths.contains(indexPath) {
            displayedCellsIndexPaths.insert(indexPath)
            CollectionViewCellAnimator.fadeAnimate(cell: cell)
        }
    }
    
}

// MARK: - Presentation Modes

extension UpcomingMoviesViewController {
    
    enum PresentationMode {
        case preview
        case detail
        
        var cellIdentifier: String {
            switch self {
            case .preview:
                return UpcomingMoviePreviewCollectionViewCell.dequeuIdentifier
            case .detail:
                return UpcomingMovieDetailCollectionViewCell.dequeuIdentifier
            }
        }
    }
    
}

// MARK: - Constants

extension UpcomingMoviesViewController {
    
    struct Constants {
        
        static let Title = NSLocalizedString("upcomingMoviesTabBarTitle", comment: "")
        static let NavigationItemTitle = NSLocalizedString("upcomingMoviesTitle", comment: "")

        static let previewCellHeight: Double = 150.0
        
        static let detailCellHeight: Double = 200.0
        static let detailCellOffset: CGFloat = 32.0
        
    }
    
}
