//
//  AccountProtocols.swift
//  UpcomingMovies
//
//  Created by Alonso on 6/27/20.
//  Copyright © 2020 Alonso. All rights reserved.
//

import UIKit
import UpcomingMoviesDomain

protocol AccountViewModelProtocol {
    
    var authPermissionURL: URL? { get }
    
    var showAuthPermission: (() -> Void)? { get set }
    var didSignIn: (() -> Void)? { get set }
    var didReceiveError: (() -> Void)? { get set }
    
    func isUserSignedIn() -> Bool
    func signOutCurrentUser()
    
    func getRequestToken()
    func getAccessToken()
    
    func currentUserAccount() -> User?
    func profileOptions() -> ProfileOptions
    
}

protocol AccountCoordinatorProtocol: class {
    
    func embedSignInViewController(on parentViewController: AccountViewControllerProtocol) -> SignInViewController
    func embedProfileViewController(on parentViewController: AccountViewControllerProtocol,
                                    for user: User?,
                                    and profileOptions: ProfileOptions) -> ProfileTableViewController
    func removeChildViewController<T: UIViewController>(_ viewController: inout T?,
                                                        from parentViewController: UIViewController)
    
    func showSavedMovies(for collectionOption: ProfileCollectionOption)
    func showCustomLists(for groupOption: ProfileGroupOption)
    func showAuthPermission(for authPermissionURL: URL?,
                            and authPermissionDelegate: AuthPermissionViewControllerDelegate)
    
}

protocol AccountViewControllerProtocol: UIViewController, SignInViewControllerDelegate, ProfileViewControllerDelegate {
}
