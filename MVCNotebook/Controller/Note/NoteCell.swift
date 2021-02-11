//
//  NoteCell.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import UIKit
protocol NoteCellDelegate: class {
    func showDelete(note: NoteMO)
}

class NoteCell: UITableViewCell {
    weak var delegate: NoteCellDelegate?
    @IBOutlet var noteTitle: UILabel!
    @IBOutlet var noteSubtitle: UILabel!
    private var note: NoteMO?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.noteTitle.text = nil
        self.noteSubtitle.text = nil
        self.note = nil
    }
    
    func cofigureNote(note: NoteMO) {
        self.note = note
        self.noteTitle.text = note.title
        guard let createdAt = note.createdAt else {return}
        self.noteSubtitle.text = HerlperDateFormatter.textFrom(date: createdAt)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        guard let note = self.note else {return}
        self.delegate?.showDelete(note: note)
    }
}
