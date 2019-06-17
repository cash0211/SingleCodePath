/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sample showing how we might create a search UI using a diffable data source
*/

import UIKit

// MARK: MountainsListSection

class MountainsListSection {
    var mountains: [MountainsController.Mountain] = []
}

extension MountainsListSection : ListSectionProtocol {

    func numberOfItems() -> Int {
        return mountains.count
    }

    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell {
        let cell = context.dequeueReusableCell(of: UITableViewCell.self, at: indexPath)
        cell.textLabel?.text = mountains[indexPath.row].name

        return cell
    }

    func didUpdate(to data: Any) {
        guard let ms = data as? [MountainsController.Mountain] else {
            return
        }
        mountains = ms
    }
}

// MARK: MountainsViewController

final class MountainsViewController: UIViewController {

    enum Section: CaseIterable {
        case main
    }
    let mountainsController = MountainsController()
    let searchBar = UISearchBar(frame: .zero)
    let tableView = UITableView(frame: .zero, style: .plain)
    var nameFilter: String?


    var mountains: [MountainsController.Mountain] = []
    lazy var listGod = ListGod()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Mountains Search"
        configureHierarchy()
        configureDataSource()
        performQuery(with: nil)
    }
}

extension MountainsViewController {
    func configureDataSource() {
        listGod.tableView = tableView
        listGod.dataSource = self
    }
    func performQuery(with filter: String?) {
        mountains = mountainsController.filteredMountains(with: filter).sorted { $0.name < $1.name }
        listGod.reloadDiffableData()
    }
}

extension MountainsViewController {
    func configureHierarchy() {
        view.backgroundColor = .white
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(searchBar)

        let views = ["cv": tableView, "searchBar": searchBar]
        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "V:[searchBar]-20-[cv]|", options: [], metrics: nil, views: views))
        constraints.append(searchBar.topAnchor.constraint(
            equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0))
        NSLayoutConstraint.activate(constraints)

        searchBar.delegate = self
    }
}

extension MountainsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performQuery(with: searchText)
    }
}

extension MountainsViewController : ListGodDataSource {
    func data(for listGod: ListGod) -> [ListDiffable] {
        return [mountains]
    }

    func listGod(_ listGod: ListGod, section: Int) -> ListSectionProtocol {
        return MountainsListSection()
    }
}
