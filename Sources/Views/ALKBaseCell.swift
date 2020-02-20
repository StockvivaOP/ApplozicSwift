//
//  ALKBaseCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

open class ALKBaseCell<T>: UITableViewCell {

    var viewModel: T?
    var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupStyle()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
        setupStyle()
    }

    func setupViews() {

    }

    func setupStyle() {

        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func update(viewModel: T) {
        self.viewModel = viewModel
    }

    class func rowHeigh(viewModel: T,width: CGFloat) -> CGFloat {
        return 44
    }

}
