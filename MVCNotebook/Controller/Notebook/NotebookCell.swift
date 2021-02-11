//
//  NotebookCell.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import UIKit

protocol NotebookCellDelegate: class {
    func showDelete(notebook: NotebookMO)
}

class NotebookCell: UITableViewCell {
    weak var delegate: NotebookCellDelegate?
    @IBOutlet var notebookTitle: UILabel!
    @IBOutlet var notebookSubtitle: UILabel!
    private var notebook: NotebookMO?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.notebookTitle.text = nil
        self.notebookSubtitle.text = nil
        self.notebook = nil        
    }
    
    func cofigureNotebook(notebook: NotebookMO) {
        self.notebook = notebook
        self.notebookTitle.text = notebook.title
        guard let createdAt = notebook.createdAt else {return}
        self.notebookSubtitle.text = HerlperDateFormatter.textFrom(date: createdAt)
    }
    
    @IBAction func deleteNotebook(_ sender: Any) {
        guard let notebook = notebook else {return}
        self.delegate?.showDelete(notebook: notebook)
    }
}


