//
//  AmityCommunityHomePageFullHeaderViewController.swift
//  AmityUIKit
//
//  Created by Mono TheForestcat on 11/4/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public class AmityCommunityHomePageFullHeaderViewController: AmityProfileViewController {

    // MARK: - Properties
    
    private var settings: AmityUserProfilePageSettings!
    private var header: AmityUserProfileHeaderViewController!
    private var bottom: AmityCommunityHomePageViewController!
//    private var bottom: AmityUserProfileBottomViewController!
    private let postButton: AmityFloatingButton = AmityFloatingButton()
    private var screenViewModel: AmityCommunityHomePageFullHeaderScreenViewModelType!
    
    // MARK: - Initializer
    
    public static func make(withUserId userId: String, settings: AmityUserProfilePageSettings = AmityUserProfilePageSettings()) -> AmityCommunityHomePageFullHeaderViewController {
        
        let viewModel: AmityCommunityHomePageFullHeaderScreenViewModelType = AmityCommunityHomePageFullHeaderScreenViewModel(userId: userId)
        
        let vc = AmityCommunityHomePageFullHeaderViewController()
        vc.header = AmityUserProfileHeaderViewController.make(withUserId: userId, settings: settings)
        vc.bottom = AmityCommunityHomePageViewController.make()
//        vc.bottom = AmityUserProfileBottomViewController.make(withUserId: userId)
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - View's life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationItem()
        setupViewModel()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setBackgroundColor(with: .white)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.reset()
    }
    
    // MARK: - Private functions
    
    private func setupView() {
        postButton.image = AmityIconSet.iconCreatePost
        postButton.add(to: view, position: .bottomRight)
        postButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            
//            let vc = AmityPostCreatorViewController.make(postTarget: .myFeed)
//            let nav = UINavigationController(rootViewController: vc)
//            nav.modalPresentationStyle = .overFullScreen
//            strongSelf.present(nav, animated: true, completion: nil)
//
            AmityEventHandler.shared.createPostBeingPrepared(from: strongSelf, postTarget: .myFeed)
        }
        postButton.isHidden = !screenViewModel.isCurrentUser
    }
    
    private func setupNavigationItem() {
        let item = UIBarButtonItem(image: AmityIconSet.iconOption, style: .plain, target: self, action: #selector(optionTap))
        item.tintColor = AmityColorSet.base
        navigationItem.rightBarButtonItem = item
    }
    
    private func setupViewModel() {
        screenViewModel.delegate = self
    }
    
    // MARK: - AmityProfileDataSource
    override func headerViewController() -> UIViewController {
        return header
    }
    
    override func bottomViewController() -> UIViewController & AmityProfilePagerAwareProtocol {
        return bottom
    }
    
    override func minHeaderHeight() -> CGFloat {
        return topInset
    }
}

private extension AmityCommunityHomePageFullHeaderViewController {
    @objc func optionTap() {
        let vc = AmityUserSettingsViewController.make(withUserId: screenViewModel.dataSource.userId)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AmityCommunityHomePageFullHeaderViewController: AmityCommunityHomePageFullHeaderScreenViewModelDelegate {
    func screenViewModel(_ viewModel: AmityCommunityHomePageFullHeaderScreenViewModelType, failure error: AmityError) {
        switch error {
        case .unknown:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        default:
            break
        }
    }
}

