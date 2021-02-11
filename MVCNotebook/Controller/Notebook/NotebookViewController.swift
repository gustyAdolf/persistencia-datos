//
//  NotebookViewController.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import UIKit
import CoreData

class NotebookViewController: UIViewController {
    
    private let reuseIdentifier = "NotebookCell"
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.register(UINib(nibName: "NotebookCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        table.estimatedRowHeight = 100
        table.rowHeight = 100
        return table
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 65))
        searchBar.showsScopeBar = true
        searchBar.delegate = self
        return searchBar
    }()
    
    let dataController: DataController
    var fetchResultController: NSFetchedResultsController<NSFetchRequestResult>?
    
    init(dataController: DataController) {
        self.dataController = dataController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFetchResultsController()
        
    }
    override func loadView() {
        view = UIView()
        title = "Notebooks"
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.tableHeaderView = searchBar
        let createNotebookRightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(plusBarButtonItemTapped))
        navigationItem.rightBarButtonItem = createNotebookRightBarButtonItem
    }
    
    
    // MARK: - Fetch result controller initializing
    func initializeFetchResultsController() {
        let viewContext = dataController.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebookCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        
        request.sortDescriptors = [notebookCreatedAtSortDescriptor]
        
        self.fetchResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.fetchResultController?.delegate = self
        
        do {
            try self.fetchResultController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook fetch.")
        }
    }
    
    // MARK: - Bar Button Items functions
    @objc
    func plusBarButtonItemTapped() {
        newNotebookAlert()
    }
    
    // MARK: - Private functions
    /// Fetch with arguments
    private func fetchNotebooks(searchBy field: String = "title", searchText: String = "") {
        guard !searchText.isEmpty else {
            initializeFetchResultsController()
            tableView.reloadData()
            return
        }
        let predicate = NSPredicate(format: "\(field) contains[c] %@", searchText)
        
        fetchResultController?.fetchRequest.predicate = predicate
        do {
            try self.fetchResultController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook filter by \(field).")
        }
        tableView.reloadData()
    }
    
    // MARK: - Alert
    
    private func newNotebookAlert() {
        let alertController = UIAlertController(title: "Create a notebook", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter notebook name"
        }
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak self] (_) in
            guard let notebookName = alertController.textFields?[0].text else {return}
            self?.dataController.performSaveInBackground({ (privateMOC) in
                NotebookMO.createNotebook(title: notebookName, createdAt: Date(), in: privateMOC)
            })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extension Table View Datasource
extension NotebookViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultController = fetchResultController {
            return fetchResultController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NotebookCell
        guard let notebook = fetchResultController?.object(at: indexPath) as? NotebookMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell?.delegate = self
        cell?.cofigureNotebook(notebook: notebook)
        return cell ?? UITableViewCell()
    }
    
}

// MARK: - Extension Table View Delegate
extension NotebookViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let notebook = fetchResultController?.object(at: indexPath) as? NotebookMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        let noteViewController = NoteViewController(notebook: notebook, dataController: self.dataController)
        navigationController?.pushViewController(noteViewController, animated: true)
    }
}

// MARK: - Extension Fetch Result Controller
extension NotebookViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            case .move, .update:
                break
            @unknown default: fatalError()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                tableView.reloadRows(at: [indexPath!], with: .fade)
            case .move:
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            @unknown default:
                fatalError()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - Extension Search Bar Delegate
extension NotebookViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchNotebooks(searchText: searchText)
    }
}

//MARK: - Notebook Cell Delegate
extension NotebookViewController: NotebookCellDelegate {
    func showDelete(notebook: NotebookMO) {
        let notebookTitle = NSLocalizedString(notebook.title ?? "", comment: "")
        showDeleteAlert("Do you want to delete \(notebookTitle)?", "All associated notes will be deleted") {[weak self] (result) in
            switch result {
                case .delete:
                    self?.dataController.delete(object: notebook)
                case .cancell: break
                    
            }
        }
    }
    
}
