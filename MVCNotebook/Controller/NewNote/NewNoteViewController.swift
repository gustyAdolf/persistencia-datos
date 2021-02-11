//
//  NewNoteViewController.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 7/2/21.
//

import UIKit

protocol NewNoteViewControllerDelegate: class {
    func newNoteCreated()
}

class NewNoteViewController: UIViewController {
    
    weak var viewDelegate: NewNoteViewControllerDelegate?
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
        collectionImagesView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NewNoteCell")
        collectionImagesView.backgroundColor = .white
        return collectionImagesView
    }()
    
    let dataController: DataController
    let notebook: NotebookMO
    var selectedImages: [PhotographMO] = []
    
    init(notebook: NotebookMO, dataController: DataController) {
        self.notebook = notebook
        self.dataController = dataController
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
        
        let createNoteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNoteBarButtonTapped))
        let pickImageBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(pickImageBarButtonTapped))
        
        navigationItem.rightBarButtonItems = [createNoteBarButtonItem, pickImageBarButtonItem]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    // MARK: - Bar Button Items functions
    @objc func createNoteBarButtonTapped() {
        if noteTitle.text?.isEmpty ?? true {
            showAlert("Wait..", "You have to enter a title to the note")
            return
        }
        let content = self.noteContent.text
        let notebook = self.notebook
        guard let title = self.noteTitle.text else {return}
        let newNote =  NoteMO.createNote(notebook: notebook, title: title, createdAt: Date(), content: content, managedObjectContext: dataController.viewContext)
        selectedImages.forEach { (photo) in
            photo.note = newNote
        }
        dataController.save()
        viewDelegate?.newNoteCreated()
        navigationController?.popViewController(animated: true)   
    }
    @objc func pickImageBarButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
           let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availableTypes
        }
        present(picker, animated: true, completion: nil)
    }
}

// MARK: - Extension Collection Data Source
extension NewNoteViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewNoteCell", for: indexPath)
        if indexPath.row < selectedImages.count {
            guard let imageData = self.selectedImages[indexPath.row].image else {return UICollectionViewCell()}
            
            let imageView = UIImageView(frame: CGRect(x:0, y:0, width:cell.frame.size.width, height:cell.frame.size.height))
            imageView.image = UIImage(data: imageData)
            cell.addSubview(imageView)            
        }
        return cell
    }
}

// MARK: - Extension Picker Image Delegate
extension NewNoteViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL,
               let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
               let imageThumbnailData = imageThumbnail.pngData() {
                
                let photo = PhotographMO.createPhoto(image: imageThumbnailData, managedObjectContext: self.dataController.viewContext)
                guard let pickedPhoto = photo else {return}
                self.selectedImages.append(pickedPhoto)
                collectionImagesView.reloadData()
            }
        }
    }
}
