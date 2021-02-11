//
//  DataController.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import CoreData

class DataController: NSObject {
    private let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    @discardableResult
    init(modelName: String, optionalStoreName: String?, completion: @escaping (NSPersistentContainer?) -> ()) {
        if let optionalStoreName = optionalStoreName {
            let managedObjectModel = Self.manageObjectModel(with: modelName)
            self.persistentContainer = NSPersistentContainer(name: optionalStoreName, managedObjectModel: managedObjectModel)
            super.init()
            
            self.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }
                completion(self?.persistentContainer)
            }
            self.persistentContainer.performBackgroundTask { (privateMOC) in }
            
        } else {
            self.persistentContainer = NSPersistentContainer(name: modelName)
            super.init()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                    if let error = error {
                        fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        completion(self?.persistentContainer)
                    }
                }
            }
        }
    }
    
    static func manageObjectModel(with name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Error could not find model.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managedObjectModel from: \(modelURL)")
        }
        
        return managedObjectModel
    }
    
    // MARK: - FETCH
    func fetch(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> Any?{
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failure to fetch notebooks with context: \(fetchRequest), \(error)")
        }
    }
    
    // MARK: - SAVE
    func save() {
        do {
            try viewContext.save()
        } catch {
            print("=== could not save view context ===")
            print("error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - RESET
    func reset() {
        viewContext.reset()
    }
    
    // MARK: - DELETE
    /// ManagedObjectContext
    func delete(object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
    /// Database
    func deleteDataBase() {
        guard let persistentStoreUrl = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {return}
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: persistentStoreUrl, ofType: NSSQLiteStoreType, options: nil)
        } catch {
            fatalError("Could not delete test database. \(error.localizedDescription)")
        }
    }
    
    /// PERFORM IN BACKGROUND
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = viewContext
        privateMOC.perform {
            block(privateMOC)
        }
    }
    /// PERFORM SAVE IN BACKGROUND
    func performSaveInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = viewContext
        privateMOC.perform { [weak self] in
            block(privateMOC)
            do {
                try privateMOC.save()
            } catch {
                fatalError("failure to save in background.")
            }
            self?.save()
        }
    }
    
    // MARK: - UPDATE
    
    func update(_ object: NSManagedObject) {
        do {
            try object.managedObjectContext?.save()

        } catch {
            fatalError("failure to update.")
        }
    }
}
