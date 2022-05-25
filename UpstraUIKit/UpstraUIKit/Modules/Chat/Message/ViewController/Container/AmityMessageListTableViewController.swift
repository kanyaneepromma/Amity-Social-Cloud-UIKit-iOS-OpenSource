//
//  AmityMessageListTableViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 30/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityMessageListTableViewController: UITableViewController {
    
    // MARK: - Properties
    private var screenViewModel: AmityMessageListScreenViewModelType!
    private var cacheIndexPath: Int = 0
    
    // MARK: - View lifecycle
    private convenience init(viewModel: AmityMessageListScreenViewModelType) {
        self.init(style: .plain)
        self.screenViewModel = viewModel
    }
    
    private override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenViewModel.action.getMessage()
    }
    
    static func make(viewModel: AmityMessageListScreenViewModelType) -> AmityMessageListTableViewController {
        return AmityMessageListTableViewController(viewModel: viewModel)
    }
    
}

// MARK: - Setup View
extension AmityMessageListTableViewController {
    func setupView() {
        tableView.separatorInset.left = UIScreen.main.bounds.width
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 0
        tableView.backgroundColor = AmityColorSet.backgroundColor
        screenViewModel.dataSource.allCellNibs.forEach {
            tableView.register($0.value, forCellReuseIdentifier: $0.key)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.separatorEffect = nil
        
    }
}

// MARK: - Update Views
extension AmityMessageListTableViewController {
    func showBottomIndicator() {
        tableView.showHeaderLoadingIndicator()
    }
    
    func hideBottomIndicator() {
        tableView.tableHeaderView = UIView()
    }
    
    func scrollToBottom(indexPath: IndexPath) {
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    func updateScrollPosition(to indexPath: IndexPath) {
        
        let contentHeight = tableView.contentSize.height
        let contentYOffset = tableView.contentOffset.y
        let viewHeight = tableView.bounds.height
        
        if cacheIndexPath == 0 {
            cacheIndexPath = indexPath.row
        }
        
        Log.add("Content Height: \(contentHeight), Content Offset: \(contentYOffset), ViewHeight: \(viewHeight)")
        
        // We update scroll position based on the view state. User can be in multiple view state.
        //
        // State 1:
        // All message fits inside the visible part of the view. We don't need to scoll
        if viewHeight >= contentHeight {
            return
        }

        // State 2:
        //
        // User is seeing the latest message. So we just scroll to the bottom when new message appears
        if viewHeight + contentYOffset >= contentHeight - 83 {
            Log.add("Scrolling tableview to show latest message")
            
            if cacheIndexPath <= indexPath.row + 1 {
                tableView.layoutIfNeeded()
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                cacheIndexPath = indexPath.row
            }
            
            return
        }
        
    }
    
}

// MARK: - Delegate
extension AmityMessageListTableViewController {
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        screenViewModel.action.loadMoreScrollUp(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let message = screenViewModel.dataSource.message(at: indexPath) else { return 0 }
        
        return cellType(for: message)?
            .height(for: message, boundingWidth: tableView.bounds.width) ?? 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let message = screenViewModel.dataSource.message(at: IndexPath(row: 0, section: section)) else { return nil }
        let dateView = AmityMessageDateView()
        dateView.text = message.date
        return dateView
    }
    
}

// MARK: - DataSource
extension AmityMessageListTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return screenViewModel.dataSource.numberOfSection()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfMessage(in: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = screenViewModel.dataSource.message(at: indexPath),
            let cellIdentifier = cellIdentifier(for: message) else {
                return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
}

extension AmityMessageListTableViewController: AmityMessageCellDelegate {
    func performEvent(_ cell: AmityMessageTableViewCell, events: AmityMessageCellEvents) {
        
        switch cell.message.messageType {
        case .audio:
            switch events {
            case .audioPlaying:
                tableView.reloadData()
            case .audioFinishPlaying:
                tableView.reloadRows(at: [cell.indexPath], with: .none)
            default:
                break
            }
        default:
            break
        }
    }
}

extension AmityMessageListTableViewController: AmityExpandableLabelDelegate {
    
    public func expandableLabeldidTap(_ label: AmityExpandableLabel) {
        // Intentionally left empty
    }
    
    public func willExpandLabel(_ label: AmityExpandableLabel) {
        tableView.beginUpdates()
    }
    
    public func didExpandLabel(_ label: AmityExpandableLabel) {
        tableView.endUpdates()
    }
    
    public func willCollapseLabel(_ label: AmityExpandableLabel) {
        tableView.beginUpdates()
    }
    
    public func didCollapseLabel(_ label: AmityExpandableLabel) {
        tableView.endUpdates()
    }
    
    public func didTapOnMention(_ label: AmityExpandableLabel, withUserId userId: String) {
        // Intentionally left empty
    }
}

// MARK: - Private functions
extension AmityMessageListTableViewController {
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
        if let cell = cell as? AmityMessageTableViewCell {
            cell.delegate = self
            cell.setViewModel(with: screenViewModel)
            cell.setIndexPath(with: indexPath)
            (cell as? AmityMessageTextTableViewCell)?.textDelegate = self
        }
        
        (cell as? AmityMessageCellProtocol)?.display(message: message)
    }
    
    private func cellIdentifier(for message: AmityMessageModel) -> String? {
        switch message.messageType {
        case .text:
            return message.isOwner ? AmityMessageTypes.textOutgoing.identifier : AmityMessageTypes.textIncoming.identifier
        case .image :
            return message.isOwner ? AmityMessageTypes.imageOutgoing.identifier : AmityMessageTypes.imageIncoming.identifier
        case .audio:
            return message.isOwner ? AmityMessageTypes.audioOutgoing.identifier : AmityMessageTypes.audioIncoming.identifier
        case .custom:
            fallthrough
        default:
            return nil
        }

    }
    
    private func cellType(for message: AmityMessageModel) -> AmityMessageCellProtocol.Type? {
        guard let identifier = cellIdentifier(for: message) else { return nil }
        return screenViewModel.allCellClasses[identifier]
    }
    
}
