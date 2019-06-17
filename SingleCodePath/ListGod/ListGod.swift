//
//  ListGod.swift
//
//  Created by cash.
//  Copyright © 2019 cash.io. All rights reserved.
//

import UIKit

// MARK: ListGodDataSource

protocol ListGodDataSource: NSObjectProtocol {
    func data(for listGod: ListGod) -> [ListDiffable]
    func listGod(_ listGod: ListGod, section: Int) -> ListSectionProtocol
}

class ListGod: NSObject {
    // MARK: Properties

    weak var dataSource: ListGodDataSource? {
        didSet {
            updateAfterPublicSettingsChange()
        }
    }

    var data: [ListDiffable] = []

    private var listSections: ListSections = []

    var tableView: UITableView = UITableView() {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            updateAfterPublicSettingsChange()
        }
    }

    // MARK: Private Methods

    private func updateAfterPublicSettingsChange() {
        // FIXME: tv
        if let ds = dataSource {
            let data = ds.data(for: self)
            updateData(data, dataSource: ds)
        }
    }

    private func updateData(_ data: [ListDiffable], dataSource: ListGodDataSource) {
        listSections.removeAll()
        for (index, value) in data.enumerated() {
            let listSection = dataSource.listGod(self, section: index)
            listSections.append(listSection)
            listSection.didUpdate(to: value)
        }
        if self.data.count == 0 {
            self.data = data
        }
    }

    // MARK: Public Methods

    public func reloadDiffableData() {
        guard let ds = dataSource else {
            return
        }
        let data = ds.data(for: self)
        updateData(data, dataSource: ds)
        withValues { (model) in
            model = data
        }
    }
}

// MARK: UITableViewDataSource

extension ListGod : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return listSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfItems = listSections[section].numberOfItems()
        return numberOfItems
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return listSections[section].titleForHeader
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let listSection = listSections[indexPath.section]

        return listSection.cellForRow(self, at: indexPath)
    }
}

// MARK: UITableViewDelegate

extension ListGod : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listSections[indexPath.section].didSelectItemAtIndex(indexPath.row)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        listSections[indexPath.section].didDeselectItemAtIndex(indexPath.row)
    }
}

extension ListGod: DataListProtocol, SingleCodePathProtocol {}

extension ListGod: ListGodContext {}
