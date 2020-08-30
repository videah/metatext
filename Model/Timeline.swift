// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum Timeline: Hashable {
    case home
    case local
    case federated
    case list(MastodonList)
    case tag(String)
}

extension Timeline {
    static let nonLists: [Timeline] = [.home, .local, .federated]

    var endpoint: TimelinesEndpoint {
        switch self {
        case .home:
            return .home
        case .local:
            return .public(local: true)
        case .federated:
            return .public(local: false)
        case let .list(list):
            return .list(id: list.id)
        case let .tag(tag):
            return .tag(tag)
        }
    }
}

extension Timeline: Identifiable {
    var id: String {
        switch self {
        case .home:
            return "home"
        case .local:
            return "local"
        case .federated:
            return "federated"
        case let .list(list):
            return list.id
        case let .tag(tag):
            return "#" + tag
        }
    }
}
