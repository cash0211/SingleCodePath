//
//  SingleCodePathProtocol.swift
//
//  Created by cash.
//  Copyright © 2019 cash.io. All rights reserved.
//

import UIKit

// MARK: ListDiffable

protocol ListDiffable {
    var diffIdentifier: String { get }
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool
}

extension Array: ListDiffable where Element: ListDiffable {
    var diffIdentifier: String {
        return reduce("", {$0 + $1.diffIdentifier})
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return diffIdentifier == object?.diffIdentifier
    }
}

// MARK: DataListProtocol

typealias DataListProtocol = DataProtocol & ListProtocol

protocol ListProtocol {
    var tableView: UITableView { get }
}

protocol DataProtocol: NSObjectProtocol {
    var data: [ListDiffable] { get set }
}

// MARK: SingleCodePathProtocol

protocol SingleCodePathProtocol {
    func withValues(_ mutations: (inout [ListDiffable]) -> Void)
    func modelDidChange(diff: IndexPathsDiff)
}

extension SingleCodePathProtocol where Self: DataListProtocol {
    func withValues(_ mutations: (inout [ListDiffable]) -> Void) {
        let oldData = data

        mutations(&data)

        func unwrap(_ object: ListDiffable) -> [ListDiffable] {
            switch object {
            case let values as [ListDiffable]:
                return values
            default:
                return [object]
            }
        }

        tableView.beginUpdates()

        for (index, (oldValue, newValue)) in nilPaddedZip(oldData, data).enumerated() {
            var new = [ListDiffable]()
            var old = [ListDiffable]()

            if let n = newValue {
                new = unwrap(n)
            }
            if let o = oldValue {
                old = unwrap(o)
            }
            let indexPathResult = ListDiffing(fromSection: index, toSection: index, oldData: old, newData: new).forBatchUpdates()
            modelDidChange(diff: indexPathResult)
        }

        tableView.endUpdates()
    }

    func modelDidChange(diff: IndexPathsDiff) {
        tableView.deleteRows(at: diff.deleted, with: .fade)
        tableView.insertRows(at: diff.inserted, with: .fade)
        diff.moved.forEach { tableView.moveRow(at: $0.from, to: $0.to) }
    }
}


