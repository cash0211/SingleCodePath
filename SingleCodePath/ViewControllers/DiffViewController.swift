/**
 Copyright (c) Facebook, Inc. and its affiliates.

 The examples provided by Facebook are for non-commercial testing and evaluation
 purposes only. Facebook reserves all rights not expressly granted.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

// MARK: Person

final class Person: ListDiffable {

    let pk: Int
    let name: String

    init(pk: Int, name: String) {
        self.pk = pk
        self.name = name
    }

    var diffIdentifier: String {
        return "\(pk)"
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? Person else { return false }
        return self.name == object.name
    }
}

// MARK: DiffListSection

final class DiffListSection {
    var people: [Person] = []
}

extension DiffListSection : ListSectionProtocol {

    public func numberOfItems() -> Int {
        return people.count
    }

    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell {
        let cell = context.dequeueReusableCell(of: UITableViewCell.self, at: indexPath)
        cell.textLabel?.text = people[indexPath.row].name
        return cell
    }

    func didUpdate(to data: Any) {
        guard let persons = data as? [Person] else {
            return
        }
        people = persons
    }
}

// MARK: DiffViewController

final class DiffViewController: UIViewController {

    let oldPeople = [
        Person(pk: 1, name: "Kevin"),
        Person(pk: 2, name: "Mike"),
        Person(pk: 3, name: "Ann"),
        Person(pk: 4, name: "Jane"),
        Person(pk: 5, name: "Philip"),
        Person(pk: 6, name: "Mona"),
        Person(pk: 7, name: "Tami"),
        Person(pk: 8, name: "Jesse"),
        Person(pk: 9, name: "Jaed")
    ]
    let newPeople = [
        Person(pk: 2, name: "Mike"),
        Person(pk: 10, name: "Marne"),
        Person(pk: 5, name: "Philip"),
        Person(pk: 1, name: "Kevin"),
        Person(pk: 3, name: "Ryan"),
        Person(pk: 8, name: "Jesse"),
        Person(pk: 7, name: "Tami"),
        Person(pk: 4, name: "Jane"),
        Person(pk: 9, name: "Chen")
    ]
    lazy var people: [Person] = {
        return self.oldPeople
    }()
    var usingOldPeople = true

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds)
        return tableView
    }()

    lazy var listGod = ListGod()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Diff Algorithm"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play,
                                                            target: self,
                                                            action: #selector(DiffViewController.onDiff))
        view.addSubview(tableView)

        listGod.tableView = tableView
        listGod.dataSource = self
    }

    @objc func onDiff() {
        let to = usingOldPeople ? newPeople : oldPeople
        usingOldPeople.toggle()
        people = to

        listGod.reloadDiffableData()
    }
}

extension DiffViewController : ListGodDataSource {
    func data(for listGod: ListGod) -> [ListDiffable] {
        return [people]
    }

    func listGod(_ listGod: ListGod, section: Int) -> ListSectionProtocol {
        return DiffListSection()
    }
}
