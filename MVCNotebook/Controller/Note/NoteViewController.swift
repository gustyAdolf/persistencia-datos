//
//  NoteViewController.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import UIKit
import CoreData

class NoteViewController: UIViewController {
    
    private let reuseIdentifier = "NoteCell"
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.register(UINib(nibName: "NoteCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
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
    let notebook: NotebookMO
    var fetchResultController: NSFetchedResultsController<NSFetchRequestResult>?
    
    
    init(notebook: NotebookMO, dataController: DataController) {
        self.notebook = notebook
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
        title = "Notes of \(NSLocalizedString(notebook.title ?? "", comment: ""))"
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.tableHeaderView = searchBar
        
        let createNoteRightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(plusBarButtonItemTapped))
        navigationItem.rightBarButtonItem = createNoteRightBarButtonItem
    }
    
    // MARK: - Bar Button Items functions
    @objc
    func plusBarButtonItemTapped() {
        let newNoteViewController = NewNoteViewController(notebook: self.notebook, dataController: self.dataController)
        newNoteViewController.viewDelegate = self
        navigationController?.pushViewController(newNoteViewController, animated: true)
    }
    
    // MARK: - Fetch result controller initializing
    func initializeFetchResultsController() {
        let viewContext = dataController.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        
        request.sortDescriptors = [noteCreatedAtSortDescriptor]
        request.predicate = NSPredicate(format: "notebook == %@", notebook)
        self.fetchResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.fetchResultController?.delegate = self
        
        do {
            try self.fetchResultController?.performFetch()
        } catch {
            print("Error while trying to perform a note fetch.")
        }
    }
    
    // MARK: - Private functions
    /// Fetch with arguments
    private func fetchNotebooks(searchBy field: String = "title", searchText: String = "") {
        guard !searchText.isEmpty else {
            initializeFetchResultsController()
            tableView.reloadData()
            return
        }
        let predicate = NSPredicate(format: "notebook == %@ AND \(field) contains[c] %@", notebook, searchText)
        fetchResultController?.fetchRequest.predicate = predicate
        do {
            try self.fetchResultController?.performFetch()
        } catch {
            print("Error while trying to perform a note filter by \(field).")
        }
        tableView.reloadData()
    }
    
    
}

// MARK: - Extension UI Table Data Source
extension NoteViewController: UITableViewDataSource {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultController = fetchResultController {
            return fetchResultController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NoteCell
        guard let note = fetchResultController?.object(at: indexPath) as? NoteMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell?.cofigureNote(note: note)
        cell?.delegate = self
        return cell ?? UITableViewCell()
    }
    
}

// MARK: - Extension UI Table View Delegate
extension NoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let note = fetchResultController?.object(at: indexPath) as? NoteMO else {fatalError("Attempt to configure cell without a managed object")}
        let noteDetailViewController = NoteDetailViewController(notebook: notebook, note: note, dataController: dataController)
        navigationController?.pushViewController(noteDetailViewController, animated: true)
    }
}

// MARK: - Extension Fetch Result Controller
extension NoteViewController: NSFetchedResultsControllerDelegate {
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
extension NoteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchNotebooks(searchText: searchText)
    }
}

// MARK: - Extension NewNoteViewControllerDelegate
extension NoteViewController: NewNoteViewControllerDelegate {
    func newNoteCreated() {
        initializeFetchResultsController()
        tableView.reloadData()
    }
}

// MARK: - Extension NoteCellDelegate
extension NoteViewController: NoteCellDelegate {
    func showDelete(note: NoteMO) {
        let noteTitle = NSLocalizedString(note.title ?? "", comment: "")
        
        showDeleteAlert("Do you want to delete \(noteTitle)?", "All associated notes will be deleted") {[weak self] (result) in
            switch result {
                case .delete:
                    self?.dataController.delete(object: note)
                case .cancell: break
            }
        }
    }
    
    
}
