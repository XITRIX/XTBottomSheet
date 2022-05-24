//
//  ScrollController.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

class ScrollController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var flag: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset.bottom = 88
        tableView.verticalScrollIndicatorInsets.bottom = 88
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension ScrollController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        flag ? 24 : 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Test cell #\(indexPath.row + 1)"
        return cell
    }
}

extension ScrollController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        flag.toggle()
        tableView.reloadData()
    }
}
