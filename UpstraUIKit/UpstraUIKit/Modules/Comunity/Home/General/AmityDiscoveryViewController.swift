//
//  AmityDiscoveryViewController.swift
//  AmityUIKit
//
//  Created by Mono TheForestcat on 18/2/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public class AmityDiscoveryViewController: AmityViewController {
    
    public var pageTitle: String = "Gallery"
    
    private var targetType = AmityPostTargetType.user
    private var targetId = ""
    private var screenViewModel: AmityDiscoveryScreenViewModelType!
    
    private var currentMedia: AmityMedia?
    
    private var currentSection: PostGallerySegmentedControlCell.Section?
    
    private let createPostButton: AmityFloatingButton = AmityFloatingButton()
    var isHiddenButtonCreate: Bool = true
    
    @IBOutlet weak var marginRight: NSLayoutConstraint!
    @IBOutlet weak var marginLeft: NSLayoutConstraint!
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    enum C {
        static let postInterimSpace: CGFloat = 8
        static let postLineSpace: CGFloat = 8
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPostButton()
        screenViewModel.delegate = self
        // Start with .image section
//        switchTo(.image)
        screenViewModel.action.loadDiscoveryItem()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        collectionView.register(PostGalleryItemCell.self)
        collectionView.register(PostGalleryFakeItemCell.self)
        collectionView.register(PostGalleryEmptyStateCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        
    }
    
    private func setupPostButton() {
        createPostButton.image = AmityIconSet.iconCreatePost
        createPostButton.add(to: view, position: .bottomRight)
        createPostButton.actionHandler = { [weak self] button in
            guard let strongSelf = self else { return }
            AmityEventHandler.shared.createPostDidTap(from: strongSelf, postTarget: .myFeed, openByProfileTrueID: true)
        }
        
        if !isHiddenButtonCreate {
            marginLeft.constant = 0
            marginRight.constant = 0
            self.view.layoutIfNeeded()
        }
        
        createPostButton.isHidden = isHiddenButtonCreate
        
    }
    
    private func presentPhotoViewer(referenceView: UIImageView, media: AmityMedia) {
        currentMedia = media
        let photoViewerVC = AmityPhotoViewerController(referencedView: referenceView, image: referenceView.image)
        photoViewerVC.dataSource = self
        photoViewerVC.delegate = self
        present(photoViewerVC, animated: true, completion: nil)
    }
    
    private func switchTo(_ section: PostGallerySegmentedControlCell.Section) {
        
        if let currentSection = currentSection, currentSection == section {
            // Prevent switch to the same session.
            return
        }
        
        currentSection = section
        
        let filterPostTypes: Set<String>?
        switch section {
        case .image:
            filterPostTypes = ["image"]
        case .video:
            filterPostTypes = ["video"]
        case .livestream:
            filterPostTypes = ["liveStream"]
        }
        
        let queryOptions = AmityPostQueryOptions(
            targetType: targetType,
            targetId: targetId,
            sortBy: .lastCreated,
            deletedOption: .notDeleted,
            filterPostTypes: filterPostTypes
        )
        screenViewModel.action.switchPostsQuery(to: queryOptions)
    }
    
    public func reloadDataImage() {
        let filterPostTypes: Set<String>?
        switch currentSection {
        case .image:
            filterPostTypes = ["image"]
        case .video:
            filterPostTypes = ["video"]
        case .livestream:
            filterPostTypes = ["liveStream"]
        case .none:
            filterPostTypes = ["image"]
        }
        let queryOptions = AmityPostQueryOptions(
            targetType: targetType,
            targetId: targetId,
            sortBy: .lastCreated,
            deletedOption: .notDeleted,
            filterPostTypes: filterPostTypes
        )
        screenViewModel.action.switchPostsQuery(to: queryOptions)
    }
    
    public static func make(
        targetType: AmityPostTargetType,
        targetId: String
    ) -> AmityDiscoveryViewController {
        
        let vc = AmityDiscoveryViewController(nibName: AmityDiscoveryViewController.identifier, bundle: AmityUIKitManager.bundle)
        
        let screenViewModel = AmityDiscoveryScreenViewModel()
        screenViewModel.setup(
            postRepository: AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
        )
        vc.screenViewModel = screenViewModel
        vc.targetType = targetType
        vc.targetId = targetId
        
        return vc
    }
    
    public static func makeByTrueID(
        targetType: AmityPostTargetType,
        targetId: String,
        isHiddenButtonCreate: Bool) -> AmityDiscoveryViewController {
            
            let vc = AmityDiscoveryViewController(nibName: AmityDiscoveryViewController.identifier, bundle: AmityUIKitManager.bundle)
            
            let screenViewModel = AmityDiscoveryScreenViewModel()
            screenViewModel.setup(
                postRepository: AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
            )
            vc.screenViewModel = screenViewModel
            vc.targetType = targetType
            vc.targetId = targetId
            vc.isHiddenButtonCreate = isHiddenButtonCreate
            return vc
    }

}

extension AmityDiscoveryViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        screenViewModel.dataSource.numberOfSections()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        screenViewModel.dataSource.numberOfItemsInSection(section)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        let item = screenViewModel.dataSource.item(at: indexPath)
//
//        switch item {
//        case .segmentedControl:
//            return (collectionView.dequeueReusableCell(for: indexPath) as PostGallerySegmentedControlCell)
//        case .post:
//            return (collectionView.dequeueReusableCell(for: indexPath) as PostGalleryItemCell)
//        case .fakePost:
//            return (collectionView.dequeueReusableCell(for: indexPath) as PostGalleryFakeItemCell)
//        case .empty:
//            return (collectionView.dequeueReusableCell(for: indexPath) as PostGalleryEmptyStateCell)
//        }
        
        return (collectionView.dequeueReusableCell(for: indexPath) as PostGalleryItemCell)
        
    }
    
}

extension AmityDiscoveryViewController {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        AmityEventHandler.shared.galleryDidScroll(scrollView)
    }
    
}



extension AmityDiscoveryViewController: UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let discoveryItem = screenViewModel.dataSource.discoveryItem(at: indexPath)
        
        let itemCell = cell as! PostGalleryItemCell
        itemCell.configure(withDisModel: discoveryItem)
        
//        let item = screenViewModel.dataSource.item(at: indexPath)
//
//        switch item {
//        case .segmentedControl:
//            let segmenteControlCell = cell as! PostGallerySegmentedControlCell
//            segmenteControlCell.setSelectedSection(currentSection, animated: false)
//            segmenteControlCell.delegate = self
//        case .post(let postObject):
//            let itemCell = cell as! PostGalleryItemCell
//            itemCell.configure(with: postObject)
//        case .fakePost:
//            return
//        case .empty:
//            // Note: The view model just tell that the datasource is empty.
//            // The view controller determine which type is currently empty from `currentSection`.
//            let emptyStateCell = cell as! PostGalleryEmptyStateCell
//            switch currentSection {
//            case .image:
//                emptyStateCell.configure(image: UIImage(named: "empty_post_gallery_image", in: AmityUIKitManager.bundle, compatibleWith: nil), text: "No photo yet")
//            case .video:
//                emptyStateCell.configure(image: UIImage(named: "empty_post_gallery_video", in: AmityUIKitManager.bundle, compatibleWith: nil), text: "No video yet")
//            case .livestream:
//                emptyStateCell.configure(image: UIImage(named: "empty_post_gallery_video", in: AmityUIKitManager.bundle, compatibleWith: nil), text: "No livestream yet")
//            case .none:
//                assertionFailure("currentSection must already have a value at this point.")
//            }
//        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        let item = screenViewModel.dataSource.item(at: indexPath)
//
//        switch item {
//        case .segmentedControl:
//            return CGSize(
//                width: collectionView.bounds.size.width,
//                height: PostGallerySegmentedControlCell.height
//            )
//        case .post, .fakePost:
//            // We calculate cell width based on available space to fit the cell.
//            let availableWidth = collectionView.bounds.width - C.postInterimSpace
//            // We divide by half, because we show post cell two items each row.
//            let cellWidth = availableWidth * 0.5
//            // We maintain recntangle ratio.
//            let cellHeight = cellWidth
//            return CGSize(width: cellWidth, height: cellHeight)
//        case .empty:
//            return CGSize(width: collectionView.bounds.width, height: PostGalleryEmptyStateCell.height)
//        }
        
        // We calculate cell width based on available space to fit the cell.
        let availableWidth = collectionView.bounds.width - C.postInterimSpace
        // We divide by half, because we show post cell two items each row.
        let cellWidth = availableWidth * 0.5
        // We maintain recntangle ratio.
        let cellHeight = cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return C.postInterimSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return C.postLineSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let currentDiscoveryItem = screenViewModel.dataSource.discoveryItem(at: indexPath)
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
//        let item = screenViewModel.dataSource.item(at: indexPath)
        
        AmityEventHandler.shared.postDidtap(from: self, postId: currentDiscoveryItem.parentPostId)
//        switch item {
//        case .post(let postObject):
//            switch postObject.dataType {
//            case "video":
////                if let originalVideo = postObject.getVideoInfo(for: .original),
////                   let url = URL(string: originalVideo.fileURL ) {
////                    presentVideoPlayer(at: url)
////                } else {
////                    print("unable to find video url for post: \(postObject.postId)")
////                }
//                AmityEventHandler.shared.postDidtap(from: self, postId: postObject.parentPostId ?? "")
//            case "image":
////                if let imageInfo = postObject.getImageInfo() {
////                    let placeholder = AmityColorSet.base.blend(.shade4).asImage()
////                    let itemCell = collectionView.cellForItem(at: indexPath) as! PostGalleryItemCell
////                    let state = AmityMediaState.downloadableImage(fileURL: imageInfo.fileURL, placeholder: placeholder)
////                    let media = AmityMedia(state: state, type: .image)
////                    presentPhotoViewer(
////                        referenceView: itemCell.imageView,
////                        media: media
////                    )
////                } else {
////                    print("unable to find image url for post: \(postObject.postId)")
////                }
//                AmityEventHandler.shared.postDidtap(from: self, postId: postObject.parentPostId ?? "")
//            case "liveStream":
//                guard let stream = postObject.getLiveStreamInfo() else {
//                    print("unable to find stream for post: \(postObject.postId)")
//                    return
//                }
//                guard !stream.isDeleted else {
//                    return
//                }
//                switch stream.status {
//                case .recorded:
//                    AmityEventHandler.shared.openRecordedLiveStreamPlayer(
//                        from: self,
//                        postId: postObject.postId,
//                        streamId: stream.streamId,
//                        recordedData: stream.recordingData
//                    )
//                case .live:
//                    AmityEventHandler.shared.openLiveStreamPlayer(
//                        from: self,
//                        postId: postObject.postId,
//                        streamId: stream.streamId
//                    )
//                case .ended, .idle:
//                    break
//                @unknown default:
//                    break
//                }
//            default:
//                assertionFailure("Not implement")
//                break
//            }
//        default:
//            break
//        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        let item = screenViewModel.dataSource.item(at: indexPath)
//        switch item {
//        case .post:
//            return true
//        default:
//            return false
//        }
        return true
    }
    
}

extension AmityDiscoveryViewController: AmityDiscoveryScreenViewModelDelegate {
    
    func screenViewModelDidUpdateDataSource(_ viewModel: AmityDiscoveryScreenViewModel) {
        collectionView.reloadData()
    }
    
}

extension AmityDiscoveryViewController: PostGallerySegmentedControlCellDelegate {
    
    func postGallerySegmentedControlCell(_ cell: PostGallerySegmentedControlCell, didTouchSection section: PostGallerySegmentedControlCell.Section) {
        
        cell.setSelectedSection(section, animated: true)
        switchTo(section)
        
    }
    
}

extension AmityDiscoveryViewController: IndicatorInfoProvider {
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
    
}

extension AmityDiscoveryViewController: AmityPhotoViewerControllerDataSource {
    
    public func numberOfItems(in photoViewerController: AmityPhotoViewerController) -> Int {
        return 1
    }
    
    public func photoViewerController(_ photoViewerController: AmityPhotoViewerController, configurePhotoAt index: Int, withImageView imageView: UIImageView) {
        
        guard let currentMedia = currentMedia else {
            return
        }
        
        switch currentMedia.state {
        case .downloadableImage(let fileURL, _):
            imageView.loadImage(with: fileURL, size: .full, placeholder: nil, optimisticLoad: true)
        default:
            assertionFailure("Not supported")
            break
        }
        
    }
    
    public func photoViewerController(_ photoViewerController: AmityPhotoViewerController, configureCell cell: AmityPhotoCollectionViewCell, forPhotoAt index: Int) {
        
        // We show only one image at a time.
        cell.zoomEnabled = true
        cell.playImageView.isHidden = true
        
    }
    
}

extension AmityDiscoveryViewController: AmityPhotoViewerControllerDelegate {
    
}