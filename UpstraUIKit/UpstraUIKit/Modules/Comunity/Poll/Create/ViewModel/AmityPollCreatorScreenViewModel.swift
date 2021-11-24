//
//  AmityPollCreatorScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 20/8/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityPollCreatorScreenViewModel: AmityPollCreatorScreenViewModelType {
    
    weak var delegate: AmityPollCreatorScreenViewModelDelegate?
    
    private let postRepository: AmityPostRepository
    private let pollRepository: AmityPollRepository
    
    var postTarget: AmityPostTarget
    var pollQuestion: String = "" { didSet { validateFieldsMandatory() } }
    var answersItem: [String] = [] { didSet { validateFieldsMandatory() } }
    var isMultipleSelection: Bool = false  { didSet { validateFieldsMandatory() } }
    private(set) var selectedDay: Int = 0
    
    var timeMilliseconds: Int = 0  { didSet { validateFieldsMandatory() } }
    
    init(postTarget: AmityPostTarget) {
        postRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
        pollRepository = AmityPollRepository(client: AmityUIKitManagerInternal.shared.client)
        self.postTarget = postTarget
    }
    
    private func validateFieldsMandatory() {
        guard pollQuestion != "", answersItem.count > 1, answersItem.filter({ $0 == ""}).isEmpty else {
            delegate?.screenViewModelCanPost(false)
            return
        }
        delegate?.screenViewModelCanPost(true)
    }
    
    func validateFieldsIsChange() {
        let result = (pollQuestion != "") || (!answersItem.isEmpty) || (isMultipleSelection) || (timeMilliseconds != 0)
        delegate?.screenViewModelFieldsChange(result)
    }
}

// MARK: - DataSource
extension AmityPollCreatorScreenViewModel {
    
    func getAnswer(at indexPath: IndexPath) -> String {
        return answersItem[indexPath.row]
    }
}

// MARK: - Action
extension AmityPollCreatorScreenViewModel {
    
    func setPollQuestion(_ text: String?) {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        pollQuestion = text
    }
    
    func setIsMultipleSelection(_ isMultiple: Bool) {
        isMultipleSelection = isMultiple
    }
    
    func setTimeToClosePoll(_ day: Int?) {
        guard let day = day else { return }
        selectedDay = day
        timeMilliseconds = (day * 1000 * 60 * 60 * 24)
    }
    
    func addNewOption(completion: () -> Void) {
        guard answersItem.count < 10 else { return }
        if answersItem.last == "" {
            return
        }
        answersItem.append("")
        completion()
    }
    
    func updateAnswer(_ text: String?, at indexPath: IndexPath?, completion: (() -> Void)?) {
        guard let text = text, let indexPath = indexPath else { return }
        answersItem[indexPath.row] = text
        completion?()
    }
    
    func deleteAnswer(at indexPath: IndexPath?, completion: (() -> Void)) {
        guard let indexPath = indexPath else { return }
        answersItem.remove(at: indexPath.row)
        completion()
    }
    
    func createPoll() {
        let builder = AmityPollCreationBuilder()
        
        for item in answersItem {
            builder.setAnswer(item)
        }
        
        builder.setQuestion(pollQuestion)
        builder.setTimeToClosePoll(timeMilliseconds)
        builder.setAnswerType(isMultipleSelection ? .multiple : .single)
        pollRepository.createPoll(builder) { [weak self] pollId, error in
            guard let strongSelf = self else { return }
            if let pollId = pollId {
                let pollPostBuilder = AmityPollPostBuilder()
                pollPostBuilder.setText(strongSelf.pollQuestion)
                pollPostBuilder.setPollId(pollId)
                switch strongSelf.postTarget {
                case .myFeed:
                    self?.postRepository.createPost(pollPostBuilder, targetId: nil, targetType: .user, completion: { post, error in
                        guard let strongSelf = self else { return }
                        let success = post != nil
                        Log.add("Text post created: \(success) Error: \(String(describing: error))")
                        strongSelf.delegate?.screenViewModelDidCreatePost(strongSelf, post: post, error: error)
                        NotificationCenter.default.post(name: NSNotification.Name.Post.didCreate, object: nil)
                    })
                case .community(let object):
                    self?.postRepository.createPost(pollPostBuilder, targetId: object.communityId, targetType: .community, completion: { post, error in
                        guard let strongSelf = self else { return }
                        let success = post != nil
                        Log.add("Text post created: \(success) Error: \(String(describing: error))")
                        strongSelf.delegate?.screenViewModelDidCreatePost(strongSelf, post: post, error: error)
                        NotificationCenter.default.post(name: NSNotification.Name.Post.didCreate, object: nil)
                    })
                }
            }
        }
    }
    
}