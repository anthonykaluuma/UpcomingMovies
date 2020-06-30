//
//  CustomListDetailViewController.swift
//  UpcomingMovies
//
//  Created by Alonso on 4/19/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit

class CustomListDetailViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var navigationBarPlaceholderView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    static var storyboardName = "CustomLists"
    
    private var headerView: CustomListDetailHeaderView!
    
    private var dataSource: SimpleTableViewDataSource<MovieCellViewModel>!
    private var displayedCellsIndexPaths = Set<IndexPath>()
    
    /// Used to determinate if the header view is being presented or not.
    private var tableViewContentOffsetY: CGFloat = 0
    
    private var isNavigationBarConfigured: Bool = false
    
    var viewModel: CustomListDetailViewModelProtocol?
    weak var coordinator: CustomListDetailCoordinatorProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindables()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defer {
            configureNavigationBar(for: tableView,
                                   and: tableViewContentOffsetY, forceUpdate: true)
        }
        guard !isNavigationBarConfigured else { return }
        isNavigationBarConfigured = true
        setClearNavigationBar()
        setupTableViewHeader()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.configureDynamicHeaderViewHeight()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showNavigationBar()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.setupTableViewHeader()
            self.configureScrollView(self.tableView, forceUpdate: true)
        })
    }

    // MARK: - Private
    
    private func setupUI() {
        setupNavigationBar()
        setupTableView()
    }
    
    private func setupNavigationBar() {
        let backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.registerNib(cellType: MovieTableViewCell.self)
    }
    
    private func setupTableViewHeader() {
        headerView = CustomListDetailHeaderView.loadFromNib()
        headerView.viewModel = viewModel?.buildHeaderViewModel()
        
        headerView.setHeaderOffset(navigationBarHeight)
        headerView.frame = CGRect(x: 0, y: 0, width: headerView.frame.width, height: headerView.frame.height - navigationBarHeight)
        
        tableView.clipsToBounds = false
        tableView.tableHeaderView = headerView
    }
    
    private func reloadTableView() {
        guard let viewModel = viewModel else { return }
        dataSource = SimpleTableViewDataSource.make(for: viewModel.movieCells)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    private func configureView(with state: CustomListDetailViewState) {
        switch state {
        case .empty:
            tableView.tableFooterView = CustomFooterView(message: "No movies to show")
        case .populated:
            tableView.tableFooterView = UIView()
        case .loading:
            tableView.tableFooterView = LoadingFooterView()
        case .error(let error):
            tableView.tableFooterView = CustomFooterView(message: error.localizedDescription)
        }
    }
    
    private func configureNavigationBar(for tableView: UITableView,
                                        and previousContentOffsetY: CGFloat,
                                        forceUpdate: Bool) {
        guard let headerView = tableView.tableHeaderView as? CustomListDetailHeaderView else {
            return
        }
        let contentOffsetY = tableView.contentOffset.y
        let headerHeight = headerView.frame.size.height - 40.0
        
        let shouldShowTitle = forceUpdate ? true : previousContentOffsetY <= headerHeight
        let shouldHideTitle = forceUpdate ? true : previousContentOffsetY > headerHeight
        
        if shouldShowTitle && contentOffsetY > headerHeight {
            showNavigationBar()
            setTitleAnimated(viewModel?.name)
        } else if shouldHideTitle && contentOffsetY <= headerHeight {
            setClearNavigationBar()
            setTitleAnimated(nil)
        }
    }

    private func showNavigationBar() {
        restoreNavigationBar(with: ColorPalette.navigationBarBackgroundColor)
    }
    
    private func hideNavigationBar() {
        setClearNavigationBar()
    }
    
    // MARK: - Reactive Behaviour
    
    private func setupBindables() {
        viewModel?.viewState.bindAndFire({ [weak self] state in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.reloadTableView()
                strongSelf.configureView(with: state)
            }
        })
        viewModel?.getListMovies()
    }

}

// MARK: - UITableViewDelegate

extension CustomListDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let viewModel = viewModel else { return }
        coordinator?.showMovieDetail(for: viewModel.movie(at: indexPath.row))
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = CustomListDetailSectionView.loadFromNib()
        view.viewModel = viewModel?.buildSectionViewModel()
        return view
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !displayedCellsIndexPaths.contains(indexPath) {
            displayedCellsIndexPaths.insert(indexPath)
            TableViewCellAnimator.fadeAnimate(cell: cell)
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension CustomListDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        configureScrollView(scrollView)
    }
    
    private func configureScrollView(_ scrollView: UIScrollView, forceUpdate: Bool = false) {
        guard let tableView = scrollView as? UITableView,
            let headerView = tableView.tableHeaderView as? CustomListDetailHeaderView else {
                return
        }
        let contentOffsetY = tableView.contentOffset.y
        
        if contentOffsetY >= 0 {
            navigationBarPlaceholderView.alpha = min(abs(contentOffsetY) / 180.0, 1.0)
        } else {
            navigationBarPlaceholderView.alpha = 0
        }
        
        // Stretchy header
        let height = headerView.initialHeightConstraintConstant - contentOffsetY
        let newHeight = max(height, 40)
        let newOffSet = newHeight - headerView.initialHeightConstraintConstant
        
        headerView.setHeaderOffset(navigationBarHeight + newOffSet)
        headerView.setPosterHeight(newHeight)
        
        // Navigation bar title
        configureNavigationBar(for: tableView, and: tableViewContentOffsetY, forceUpdate: forceUpdate)
        
        tableViewContentOffsetY = scrollView.contentOffset.y
    }
    
}
