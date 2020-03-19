//
//  Exsion+ViewController.swift
//  DrawGraphicsAndLine
//
//  Created by ri on 2019/07/26.
//  Copyright © 2019 Lee. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showActionSheet(_ view: UIViewController, _ title: String, _ btnArray: [String]? = nil, _ block: ((UIAlertAction)->())? = nil) {
        let actionsheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for str in btnArray ?? [""] {
            let action = UIAlertAction(title: str, style: .default) {(action) in
                if block != nil {
                    block!(action)
                }
            }
            actionsheet.addAction(action)
        }
        let cancelaction = UIAlertAction(title: "Cancel", style: .cancel)
        actionsheet.addAction(cancelaction)
        DispatchQueue.main.async {
            view.present(actionsheet, animated: true, completion: nil)
        }
    }
    
}
