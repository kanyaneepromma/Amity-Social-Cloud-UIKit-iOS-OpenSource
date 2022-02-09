//
//  AmityTrueEventHandler.swift
//  AmityUIKit
//
//  Created by Mono TheForestcat on 8/2/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public class AmityCreateChannelHandler {
    public static let shared = AmityCreateChannelHandler()
    private var channelToken: AmityNotificationToken?
    private var existingChannelToken: AmityNotificationToken?
    private var channelRepository: AmityChannelRepository?
    private var roleController: AmityChannelRoleController?
    
    public init() {
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    public func createChannel(trueUser: TrueUser, completion: @escaping(Result<String,Error>) -> ()) {
        let users = [trueUser]
        var allUsers = users
        var currentUser: TrueUser?
        if let user = AmityUIKitManagerInternal.shared.client.currentUser?.object {
            let userModel = TrueUser(userId: user.userId, displayname: user.displayName ?? "")
            currentUser = userModel
            allUsers.append(userModel)
        }
        let builder = AmityCommunityChannelBuilder()
        let userIds = allUsers.map{ $0.userId }
        let channelId = userIds.sorted().joined(separator: "-")
        let channelDisplayName = users.count == 1 ? users.first?.displayName ?? "" : allUsers.map { $0.displayName }.joined(separator: "-")
        builder.setUserIds(userIds)
        builder.setId(channelId)
        let metaData: [String:Any] = [
            "isDirectChat": allUsers.count == 2,
            "creatorId": currentUser?.userId ?? "",
            "sdk_type":"ios",
            "userIds": userIds
        ]
        builder.setMetadata(metaData)
        builder.setDisplayName(channelDisplayName)
        builder.setTags(["ch-comm","ios-sdk"])
        existingChannelToken?.invalidate()
        existingChannelToken = channelRepository?.getChannel(channelId).observe({ [weak self] (channel, error) in
            guard let weakSelf = self else { return }
            if error != nil {
                weakSelf.createNewCommiunityChannel(builder: builder) { result in
                    switch result {
                    case .success(let channelId):
                        completion(.success(channelId))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            guard channel.object != nil else { return }
            weakSelf.channelRepository?.joinChannel(channelId)
            weakSelf.existingChannelToken?.invalidate()
            completion(.success(channelId))
        })
        
    }
    
    func createNewCommiunityChannel(builder: AmityCommunityChannelBuilder, completion: @escaping(Result<String,Error>) -> ()) {
        let channelObject = channelRepository?.createChannel().community(with: builder)
        channelToken?.invalidate()
        channelToken = channelObject?.observe {[weak self] channelObject, error in
            guard let weakSelf = self else { return }
            if let error = error {
                completion(.failure(error))
                AmityHUD.show(.error(message: error.localizedDescription))
            }
            if let channelId = channelObject.object?.channelId,
               let meta = builder.channelMetadata,
               let creatorId = meta["creatorId"] as? String {
                weakSelf.channelToken?.invalidate()
                weakSelf.addCreatorRole(channelId: channelId, userId: creatorId)
                completion(.success(channelId))
            }
        }
    }
    
    func addCreatorRole(channelId: String, userId: String) {
        roleController = AmityChannelRoleController(channelId: channelId)
        roleController?.add(role: .creator, userIds: [userId]) { [weak self] error in }
    }
    
}
