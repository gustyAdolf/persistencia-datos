//
//  SceneDelegate.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var dataController: DataController!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        dataController = DataController(modelName: "MVCNotebookModel", optionalStoreName: nil, completion: { [weak self] persistentContainer in
            guard persistentContainer != nil else {fatalError("The Core Data Stack was not created")}
            self?.preloadData()
        })
 
        let notebookViewController = NotebookViewController(dataController: self.dataController)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        self.window?.rootViewController = UINavigationController(rootViewController: notebookViewController)
        self.window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    // MARK: - Private functions
    private func preloadData() {
        guard !UserDefaults.standard.bool(forKey: "hasPreloadData") else {
            return
        }
        UserDefaults.standard.set(true, forKey: "hasPreloadData")
        
        // Create some mock notebook
        guard let notebook = NotebookMO.createNotebook(title: "My first notebook", createdAt: Date(), in: dataController.viewContext) else {return}
        guard let notebook2 = NotebookMO.createNotebook(title: "Another notebook", createdAt: Date(), in: dataController.viewContext) else {return}
        
        NoteMO.createNote(notebook: notebook, title: "Nota 1", createdAt: Date(), content: "Esta nota es una prueba", managedObjectContext: dataController.viewContext)
        
        NoteMO.createNote(notebook: notebook, title: "Nota 2", createdAt: Date(), content: "Esta nota es otra prueba", managedObjectContext: dataController.viewContext)
        
        NoteMO.createNote(notebook: notebook, title: "Nota 3", createdAt: Date(), content: "Esta nota es otra prueba 3", managedObjectContext: dataController.viewContext)
        
        NoteMO.createNote(notebook: notebook2, title: "Apuntes varios", createdAt: Date(), content: "Esta nota es otra prueba", managedObjectContext: dataController.viewContext)
        
        NoteMO.createNote(notebook: notebook2, title: "Recetas", createdAt: Date(), content: "Esta nota es otra prueba 3", managedObjectContext: dataController.viewContext)
        
        dataController.save()
    }
}

