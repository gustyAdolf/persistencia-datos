//
//  PhotographMO+CoreDataClass.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//
//

import Foundation
import CoreData

@objc(PhotographMO)
public class PhotographMO: NSManagedObject {

    static func createPhoto(image: Data, managedObjectContext: NSManagedObjectContext) -> PhotographMO? {
        let photo = NSEntityDescription.insertNewObject(forEntityName: "Photograph", into: managedObjectContext) as? PhotographMO
        photo?.image = image
        photo?.createdAt = Date()
        return photo
    }
}
