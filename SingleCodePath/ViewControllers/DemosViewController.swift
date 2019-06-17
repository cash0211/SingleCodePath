//
//  DemosViewController.swift
//
//  Created by cash.
//  Copyright © 2019 cash.io. All rights reserved.
//

import UIKit

// MARK: DemoItem

final class DemoItem: NSObject {

    let identifier = UUID()
    let name: String
    let controllerClass: UIViewController.Type

    init(name: String,
         controllerClass: UIViewController.Type) {
        self.name = name
        self.controllerClass = controllerClass
    }

    static func == (lhs: DemoItem, rhs: DemoItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension DemoItem: ListDiffable {
    var diffIdentifier: String {
        return "\(identifier)"
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let demoItem = object as? DemoItem else {
            return false
        }
        return self == demoItem
    }
}

// MARK: DemosListSection

final class DemosListSection {
    var demoItems: [DemoItem] = []

    weak var viewController: DemosViewController?

    init(with viewController: DemosViewController) {
        self.viewController = viewController
    }
}

extension DemosListSection : ListSectionProtocol {

    public func numberOfItems() -> Int {
        return demoItems.count
    }

    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell {
        let cell = context.dequeueReusableCell(of: UITableViewCell.self, at: indexPath)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.text = demoItems[indexPath.row].name
        return cell
    }

    func didUpdate(to data: Any) {
        guard let demoItems = data as? [DemoItem] else {
            return
        }
        self.demoItems = demoItems
    }

    public func didSelectItemAtIndex(_ index: Int) {
        let demoItem = demoItems[index]

        viewController?.tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        viewController?.navigationController?.pushViewController(demoItem.controllerClass.init(), animated: true)
    }
}

// MARK: DemosViewController

final class DemosViewController: UIViewController {

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds)
        return tableView
    }()

    lazy var listGod = ListGod()

    let demos: [DemoItem] = [
        DemoItem(name: "Diff Algorithm",
                 controllerClass: DiffViewController.self),
        DemoItem(name: "Mountains Search",
                 controllerClass: MountainsViewController.self),
        DemoItem(name: "Settings: Wi-Fi",
                 controllerClass: WiFiSettingsViewController.self)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)

        listGod.tableView = tableView
        listGod.dataSource = self
    }
}

extension DemosViewController : ListGodDataSource {
    func data(for listGod: ListGod) -> [ListDiffable] {
        return [demos]
    }

    func listGod(_ listGod: ListGod, section: Int) -> ListSectionProtocol {
        return DemosListSection(with: self)
    }
}
