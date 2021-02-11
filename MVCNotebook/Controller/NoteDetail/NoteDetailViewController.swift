//
//  NoteDetailViewController.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 7/2/21.
//

import UIKit
import CoreData

class NoteDetailViewController: UIViewController {
    
    lazy var noteTitle: UITextField = {
        let noteTitle = UITextField()
        noteTitle.translatesAutoresizingMaskIntoConstraints = false
        noteTitle.placeholder = "Enter note name"
        return noteTitle
    }()
    
    lazy var noteContent: UITextField = {
        let noteContent = UITextField()
        noteContent.translatesAutoresizingMaskIntoConstraints = false
        noteContent.placeholder = "Type content of this note..."
        return noteContent
    }()
    
    lazy var collectionImagesView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 100, height: 100)
        let collectionImagesView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionImagesView.translatesAutoresizingMaskIntoConstraints = false
        collectionImagesView.dataSource = self
        collectionImagesView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NoteDetailImage")
        collectionImagesView.backgroundColor = .white
        return collectionImagesView
    }()
    
    let dataController: DataController
    let notebook: NotebookMO
    var note: NoteMO
    var fetchResultController: NSFetchedResultsController<NSFetchRequestResult>?
    var blockOperation = BlockOperation()
    
    init(notebook: NotebookMO, note: NoteMO, dataController: DataController) {
        self.notebook = notebook
        self.dataController = dataController
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        view = UIView()
        
        view.backgroundColor = .white
        view.addSubview(noteTitle)
        NSLayoutConstraint.activate([
            noteTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            noteTitle.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            noteTitle.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16)
        ])
        
        view.addSubview(noteContent)
        NSLayoutConstraint.activate([
            noteContent.topAnchor.constraint(equalTo: noteTitle.bottomAnchor, constant: 5),
            noteContent.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            noteContent.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16)
        ])
        
        view.addSubview(collectionImagesView)
        NSLayoutConstraint.activate([
            collectionImagesView.topAnchor.constraint(equalTo: noteContent.bottomAnchor, constant: 5),
            collectionImagesView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            collectionImagesView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            collectionImagesView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 16)
        ])
        
        let backBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(backBarButtomTapped))
        let photoBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(photoBarButtonTapped))
        navigationItem.leftBarButtonItem = backBarButtonItem
        navigationItem.rightBarButtonItem = photoBarButtonItem
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.noteTitle.text = note.title
        self.noteContent.text = note.content
        initializeFetchResultsController()
        
    }
    // MARK: - Bar Button Items functions
    @objc
    func backBarButtomTapped() {
        updateNote()
        navigationController?.popViewController(animated: true)
    }
    @objc
    func photoBarButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
           let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availableTypes
        }
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Fetch result controller init
    func initializeFetchResultsController() {
        let viewContext = dataController.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        let photoImageSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        
        request.sortDescriptors = [photoImageSortDescriptor]
        request.predicate = NSPredicate(format: "note == %@", note)
        self.fetchResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.fetchResultController?.delegate = self
        
        do {
            try self.fetchResultController?.performFetch()
        } catch {
            print("Error while trying to perform a note fetch.")
        }
    }
    
    // MARK: - Private functions
    func updateNote() {
        guard let newTitle = noteTitle.text,
              let newContent = noteContent.text else {return}
        note.setValue(newTitle, forKey: "title")
        note.setValue(newContent, forKey: "content")
        dataController.update(note)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.fetchResultController?.delegate = nil
    }
}

// MARK: - Extension

extension NoteDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchResultController = fetchResultController {
            return fetchResultController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteDetailImage", for: indexPath)
        guard let photo = fetchResultController?.object(at: indexPath) as? PhotographMO,
              let imageData = photo.image else {fatalError()}
        let imageView = UIImageView(frame: CGRect(x:0, y:0, width:cell.frame.size.width, height:cell.frame.size.height))
        imageView.image = UIImage(data: imageData)
        cell.addSubview(imageView)
        return cell
    }
}


// MARK: - Extension Fetch Result Controller
extension NoteDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)
        switch type {
            case .insert:
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.insertSections(sectionIndexSet)
                }
            case .delete:
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.deleteSections(sectionIndexSet)
                }
            case .update:
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.reloadSections(sectionIndexSet)
                }
            case .move:
                assertionFailure()
                break
            @unknown default:
                fatalError()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { break }
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.insertItems(at: [newIndexPath])
                }
            case .delete:
                guard let indexPath = indexPath else { break }
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.deleteItems(at: [indexPath])
                }
            case .update:
                guard let indexPath = indexPath else { break }
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.reloadItems(at: [indexPath])
                }
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                blockOperation.addExecutionBlock {
                    self.collectionImagesView.moveItem(at: indexPath, to: newIndexPath)
                }
            @unknown default:
                fatalError()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionImagesView.performBatchUpdates({
            self.blockOperation.start()
        }, completion: nil)
    }
    
}

// MARK: - Extension Picker Image Delegate
extension NoteDetailViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL,
               let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
               let imageThumbnailData = imageThumbnail.pngData() {
                
                dataController.performInBackground { [weak self] (privateMOC) in
                    let noteId = self?.note.objectID
                    let copyNote = privateMOC.object(with: noteId!) as! NoteMO
                    let photo = PhotographMO.createPhoto(image: imageThumbnailData, managedObjectContext: privateMOC)
                    guard let pickedPhoto = photo else {return}
                    pickedPhoto.note = copyNote
                    do {
                        try privateMOC.save()
                    } catch {
                        fatalError("\(error.localizedDescription)")
                    }
                }
                
            }
        }
    }
}
