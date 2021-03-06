//
//  TextTableViewController.swift
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class TextTableViewController: UITableViewController, UITextViewDelegate
{
    // MARK: Public API
    
    // outer Array is the sections
    // inner Array is the data in each row

    var data: [Array<String>]? {
        didSet {
            if oldValue == nil || data == nil {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: Text View Handling
    
    // this can be overridden to customize the look of the UITextViews

    func createTextViewForIndexPath(_ indexPath: IndexPath?) -> UITextView {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        textView.isScrollEnabled = true
        textView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        textView.isOpaque = false
        textView.backgroundColor = UIColor.clear
        return textView
    }
    
    fileprivate func cellForTextView(_ textView: UITextView) -> UITableViewCell? {
        var view = textView.superview
        while (view != nil) && !(view! is UITableViewCell) { view = view!.superview }
        return view as? UITableViewCell
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?[section].count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let textView = createTextViewForIndexPath(indexPath)
        textView.frame = cell.contentView.bounds
        textViewWidth = textView.frame.size.width
        textView.text = data?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        textView.delegate = self
        cell.contentView.addSubview(textView)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        if data != nil {
            data![(toIndexPath as NSIndexPath).section].insert(data![(fromIndexPath as NSIndexPath).section][(fromIndexPath as NSIndexPath).row], at: (toIndexPath as NSIndexPath).row)
            let fromRow = (fromIndexPath as NSIndexPath).row + (((toIndexPath as NSIndexPath).row < (fromIndexPath as NSIndexPath).row) ? 1 : 0)
            data![(fromIndexPath as NSIndexPath).section].remove(at: fromRow)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            data?[(indexPath as NSIndexPath).section].remove(at: (indexPath as NSIndexPath).row)
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRowAtIndexPath(indexPath)
    }
    
    fileprivate var textViewWidth: CGFloat?
    fileprivate lazy var sizingTextView: UITextView = self.createTextViewForIndexPath(nil)

    fileprivate func heightForRowAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section < data?.count && (indexPath as NSIndexPath).row < data?[(indexPath as NSIndexPath).section].count {
            if let contents = data?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row] {
                if let textView = visibleTextViewWithContents(contents) {
                    return textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: tableView.bounds.size.height)).height + 1.0
                } else {
                    let width = textViewWidth ?? tableView.bounds.size.width
                    sizingTextView.text = contents
                    return sizingTextView.sizeThatFits(CGSize(width: width, height: tableView.bounds.size.height)).height + 1.0
                }
            }
        }
        return UITableViewAutomaticDimension
    }
    
    fileprivate func visibleTextViewWithContents(_ contents: String) -> UITextView? {
        for cell in tableView.visibleCells {
            for subview in cell.contentView.subviews {
                if let textView = subview as? UITextView , textView.text == contents {
                    return textView
                }
            }
        }
        return nil
    }

    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        if let cell = cellForTextView(textView), let indexPath = tableView.indexPath(for: cell) {
            data?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row] = textView.text
        }
        updateRowHeights()
        let editingRect = textView.convert(textView.bounds, to: tableView)
        if !tableView.bounds.contains(editingRect) {
            // should actually scroll to be clear of keyboard too
            // but for now at least scroll to visible ...
            tableView.scrollRectToVisible(editingRect, animated: true)
        }
        textView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.rangeOfCharacter(from: CharacterSet.newlines) != nil {
            returnKeyPressed(inTextView: textView)
            return false
        } else {
            return true
        }
    }
    
    func returnKeyPressed(inTextView textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    @objc fileprivate func updateRowHeights() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // MARK: Content Size Category Change Notifications
    
    fileprivate var contentSizeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        contentSizeObserver = NotificationCenter.default.addObserver(
        forName: NSNotification.Name.UIContentSizeCategoryDidChange,
        object: nil,
        queue: OperationQueue.main
        ) { notification in
            // give all the UITextViews a chance to react, then resize our row heights
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateRowHeights), userInfo: nil, repeats: false)
        }
    }
    
    deinit {
        if contentSizeObserver != nil {
            NotificationCenter.default.removeObserver(contentSizeObserver!)
            contentSizeObserver = nil
        }
    }
}
