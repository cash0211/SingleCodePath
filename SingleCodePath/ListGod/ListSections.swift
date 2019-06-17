//
//  ListSections.swift
//
//  Created by cash.
//  Copyright © 2019 cash.io. All rights reserved.
//

import UIKit

// MARK: ListGodContext

protocol ListGodContext {
    func dequeueReusableCell<T: UITableViewCell>(of type: T.Type, at indexPath: IndexPath) -> T
}

extension ListGodContext where Self : DataListProtocol {
    func dequeueReusableCell<T: UITableViewCell>(of type: T.Type, at indexPath: IndexPath) -> T {
        let cell: T = tableView.dequeueReusableCell(for: indexPath)
        return cell
    }
}

// MARK: ListSectionProtocol

protocol ListSectionProtocol : class {
    var identifiers   : String { get }
    var titleForHeader: String { get }
    
    func numberOfItems() -> Int
    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell
    
    func didUpdate(to data: Any)

    func didSelectItemAtIndex(_ index: Int)
    func didDeselectItemAtIndex(_ index: Int)
}

extension ListSectionProtocol {
    var identifiers   : String  {
        return "\(self.self)"
    }
    
    var titleForHeader: String {
        return ""
    }
    
    func numberOfItems() -> Int {
        return 1
    }
    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    func didUpdate(to data: Any) {}
    func didSelectItemAtIndex(_ index: Int) {}
    func didDeselectItemAtIndex(_ index: Int) {}
}

// MARK: IdentifierProtocol

protocol IdentifierProtocol {
    static var reuseIdentifier: String { get }
}

extension IdentifierProtocol {
    static var reuseIdentifier: String {
        return "\(Self.self)"
    }
}

extension UITableViewCell: IdentifierProtocol {}

extension UITableView {
    private static var _dequeueReusableCellIdentifiers = Set<String>()
    
    func register<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        var identifiers = UITableView._dequeueReusableCellIdentifiers
        let reuseIdentifier = T.reuseIdentifier
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)
            register(T.self)
        }
        
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Unable to Dequeue Reusable Table View Cell")
        }
        
        return cell
    }
}

extension Array where Element == ListSectionProtocol {
    
    static let empty: [ListSectionProtocol] = []
    
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.identifiers.lowercased() == lowercasedName }
    }
}

// MARK: ListSections

struct ListSections {
    // MARK: Properties

    private var _objects = [ListSectionProtocol]()
    var objects: [ListSectionProtocol] { return _objects }

    public var count: Int {
        return _objects.count
    }

    // MARK: Initialization

    init(_ objects: [ListSectionProtocol]) {
        _objects = objects
    }

    mutating func append(_ object: ListSectionProtocol) {
        _objects.append(object)
    }

    mutating func remove(_ object: ListSectionProtocol) {
        guard let index = _objects.index(of: object.identifiers) else { return }

        _objects.remove(at: index)
    }

    mutating func removeLast() -> ListSectionProtocol {
        return _objects.removeLast()
    }

    mutating func removeAll() {
        return _objects.removeAll()
    }

    public subscript(_ index: Int) -> ListSectionProtocol {
        get {
            return _objects[index]
        }
        set {
            _objects[index] = newValue
        }
    }
}

extension ListSections : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ListSectionProtocol...) {
        self.init(elements)
    }
}

extension ListSections : Sequence {
    public func makeIterator() -> IndexingIterator<[ListSectionProtocol]> {
        return _objects.makeIterator()
    }
}

extension ListSections : Collection {
    public var startIndex: Int {
        return _objects.startIndex
    }

    public var endIndex: Int {
        return _objects.endIndex
    }

    public func index(after i: Int) -> Int {
        return _objects.index(after: i)
    }
}

extension ListSections : CustomStringConvertible {
    public var description: String {
        return _objects.map { "\($0.self)" }.joined(separator: "\n")
    }
}
