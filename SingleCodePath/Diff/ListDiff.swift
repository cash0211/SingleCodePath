//
//  ListDiff.swift
//
//  Created by cash.
//  Copyright © 2019 cash.io. All rights reserved.
//

import UIKit

class ListEntry {
    var oldCounter: Int = 0
    var newCounter: Int = 0
    var oldIndexes: [Int] = []
    var updated: Bool = false
}

class ListRecord {
    var entry: ListEntry = ListEntry()
    var index: Int = NSNotFound
}

struct IndexPathsDiff {
    // MARK: Types
    
    enum Diff {
        case inserted([IndexPath])
        case deleted([IndexPath])
        case updated([IndexPath])
        case moved([(from: IndexPath, to: IndexPath)])
    }
    
    // MARK: Properties
    
    var inserted: [IndexPath] = []
    var deleted: [IndexPath] = []
    var updated: [IndexPath] = []
    var moved: [(from: IndexPath, to: IndexPath)] = []
    
    init(inserted: [IndexPath], deleted: [IndexPath], updated: [IndexPath], moved: [(from: IndexPath, to: IndexPath)]) {
        self.inserted = inserted
        self.deleted = deleted
        self.updated = updated
        self.moved = moved
    }
    
    init(diffs: [Diff]) {
        var inserted: [IndexPath] = []
        var deleted: [IndexPath] = []
        var updated: [IndexPath] = []
        var moved: [(from: IndexPath, to: IndexPath)] = []
        diffs.forEach {
            switch $0 {
            case .inserted(let indexPaths):
                inserted = indexPaths
            case .deleted(let indexPaths):
                deleted = indexPaths
            case .updated(let indexPaths):
                updated = indexPaths
            case .moved(let indexPaths):
                moved = indexPaths
            }
        }
        self.init(inserted: inserted, deleted: deleted, updated: updated, moved: moved)
    }
    
    func forBatchUpdates() -> IndexPathsDiff {
        var deleted = Set(self.deleted)
        var inserted = Set(self.inserted)
        var filteredUpdated = Set(self.updated)
        
        var filteredMoved = self.moved
        
        let moveCount = moved.count
        for i in (0 ..< moveCount).reversed() {
            let move = moved[i]
            if filteredUpdated.contains(move.from) {
                filteredMoved.remove(at: i)
                filteredUpdated.remove(move.from)
                deleted.insert(move.from)
                inserted.insert(move.to)
            }
        }
        
        for indexPath in filteredUpdated {
            deleted.insert(indexPath)
            inserted.insert(indexPath)
        }
        
        return IndexPathsDiff(inserted: [IndexPath](inserted), deleted: [IndexPath](deleted), updated: [], moved: filteredMoved)
    }
}

func indexPaths(data: [ListDiffable], section: Int) -> [IndexPath] {
    return data.enumerated().map { (index, _) -> IndexPath in
        IndexPath(row: index, section: section)
    }
}

func ListDiffing(fromSection: Int,
                 toSection: Int,
                 oldData: [ListDiffable],
                 newData: [ListDiffable]) -> IndexPathsDiff {
    let newCount = newData.count
    let oldCount = oldData.count
    
    if newCount == 0 {
        return IndexPathsDiff(diffs: [.deleted(indexPaths(data: oldData, section: fromSection))])
    }
    
    if oldCount == 0 {
        return IndexPathsDiff(diffs: [.inserted(indexPaths(data: newData, section: fromSection))])
    }
    
    var table = [String : ListEntry]()
    let tableEntry = { (key: String) -> ListEntry in
        if let value = table[key] {
            return value
        }
        let entry = ListEntry()
        table[key] = entry
        return entry
    }
    
    let newResultsArray = (0 ..< newCount).map { _ in return ListRecord() }
    for i in 0 ..< newCount {
        let key = newData[i].diffIdentifier
        let entry = tableEntry(key)
        entry.newCounter += 1
        
        entry.oldIndexes.append(NSNotFound)
        
        newResultsArray[i].entry = entry
    }
    
    let oldResultsArray = (0 ..< oldCount).map { _ in return ListRecord() }
    for i in (0 ..< oldCount).reversed() {
        let key = oldData[i].diffIdentifier
        let entry = tableEntry(key)
        entry.oldCounter += 1
        
        entry.oldIndexes.append(i)
        
        oldResultsArray[i].entry = entry
    }
    
    for i in 0 ..< newCount {
        let entry = newResultsArray[i].entry
        
        guard let originalIndex = entry.oldIndexes.popLast() else {
            fatalError("Old indexes is empty while iterating new item \(i). Should have NSNotFound")
        }
        
        if originalIndex < oldCount {
            let n = newData[i]
            let o = oldData[originalIndex]
            if  !n.isEqual(toDiffableObject: o) {
                entry.updated = true
            }
        }
        if originalIndex != NSNotFound,
            entry.newCounter > 0,
            entry.oldCounter > 0 {
            newResultsArray[i].index = originalIndex
            oldResultsArray[originalIndex].index = i
        }
    }
    
    var mInserts: [IndexPath] = []
    var mMoves: [(from: IndexPath, to: IndexPath)] = []
    var mUpdates: [IndexPath] = []
    var mDeletes: [IndexPath] = []
    
    var deleteOffsets = [Int](repeating: 0, count: oldCount)
    var insertOffsets = [Int](repeating: 0, count: newCount)
    var runningOffset = 0
    
    for i in 0 ..< oldCount {
        deleteOffsets[i] = runningOffset
        let record = oldResultsArray[i]
        if record.index == NSNotFound {
            mDeletes.append(IndexPath(row: i, section: fromSection))
            runningOffset += 1
        }
    }
    
    runningOffset = 0
    
    for i in 0 ..< newCount {
        insertOffsets[i] = runningOffset
        let record = newResultsArray[i];
        let oldIndex = record.index
        
        if record.index == NSNotFound {
            mInserts.append(IndexPath(row: i, section: toSection))
            runningOffset += 1
        } else {
            if record.entry.updated {
                mUpdates.append(IndexPath(row: oldIndex, section: fromSection))
            }
            
            let insertOffset = insertOffsets[i]
            let deleteOffset = deleteOffsets[oldIndex]
            if (oldIndex - deleteOffset + insertOffset) != i {
                let from = IndexPath(row: oldIndex, section: fromSection)
                let to = IndexPath(row: i, section: toSection)
                mMoves.append((from, to))
            }
        }
    }
    
    guard (oldCount + mInserts.count - mDeletes.count) == newCount else {
        fatalError("Sanity check failed applying \(mInserts.count) inserts and \(mDeletes.count) deletes to old count \(oldCount) equaling new count \(newCount)")
    }

    return IndexPathsDiff(inserted: mInserts, deleted: mDeletes, updated: mUpdates, moved: mMoves)
}
