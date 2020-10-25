// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class TableViewDataSource: UITableViewDiffableDataSource<Int, CollectionItem> {
    private let updateQueue =
        DispatchQueue(label: "com.metabolist.metatext.collection-data-source.update-queue")

    init(tableView: UITableView, viewModelProvider: @escaping (IndexPath) -> CollectionItemViewModel) {
        for cellClass in CollectionItem.cellClasses {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: item.cellClass),
                for: indexPath)

            switch (cell, viewModelProvider(indexPath)) {
            case let (statusListCell as StatusListCell, statusViewModel as StatusViewModel):
                statusListCell.viewModel = statusViewModel
            case let (accountListCell as AccountListCell, accountViewModel as AccountViewModel):
                accountListCell.viewModel = accountViewModel
            case let (loadMoreCell as LoadMoreCell, loadMoreViewModel as LoadMoreViewModel):
                loadMoreCell.viewModel = loadMoreViewModel
            default:
                break
            }

            return cell
        }
    }

    override func apply(_ snapshot: NSDiffableDataSourceSnapshot<Int, CollectionItem>,
                        animatingDifferences: Bool = true,
                        completion: (() -> Void)? = nil) {
        updateQueue.async {
            super.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
}