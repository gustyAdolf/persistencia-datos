//
//  NotebookMO+CoreDataClass.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//
//

import Foundation
import CoreData


public class NotebookMO: NSManagedObject {
    @discardableResult
    static func createNotebook(title: String, createdAt: Date, in managedObjectContext: NSManagedObjectContext) -> NotebookMO? {
        let notebook = NSEntityDescription.insertNewObject(forEntityName: "Notebook", into: managedObjectContext) as? NotebookMO
        notebook?.title = title
        notebook?.createdAt = createdAt
        return notebook
    }
}
