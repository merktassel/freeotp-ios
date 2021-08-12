//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

class EditViewController: UIViewController, UITextFieldDelegate {
    var token: Token!

    @IBOutlet var image: UIButton!
    @IBOutlet var issuer: UITextField!
    @IBOutlet var label: UITextField!

    @IBOutlet var trashButton: UIBarButtonItem!

    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var lockSwitch: UISwitch!

    @IBAction func lockClicked(_ sender: UISwitch) {
        token.locked = sender.isOn
        sender.isOn = token.locked
    }

    @IBAction func trashClicked(_ sender: UIBarButtonItem) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let removeAction = UIAlertAction(title: "Remove token", style: .destructive) { action -> Void in
            TokenStore().erase(token: self.token)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheetController.addAction(removeAction)
        actionSheetController.addAction(cancelAction)

        self.present(actionSheetController, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let locking: Bool = Token.store.lockingSupported
        lockLabel.isEnabled = locking
        lockSwitch.isEnabled = locking
        lockSwitch.isOn = token.locked

        self.navigationItem.rightBarButtonItems = [self.trashButton]
        token2UI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.app.background
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let t = token {
            Token.store.save(t)
        }
    }
    
    @discardableResult func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        switch textField {
        case self.issuer:
            token.issuer = str
        case self.label:
            token.label = str
        default:
            return false
        }

        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    fileprivate func token2UI() {
        issuer.text = token?.issuer
        label.text = token?.label

        let size = self.image.imageView?.image?.size
        let imageSize = CGSize(width: size!.width, height: size!.height)
        
        let icon = TokenIcon()
        var iconName = ""
        
        if let image = token.image {
            if image.hasSuffix("/FreeOTP.app/default.png") {
                let defaultIcon = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)
                self.image.setImage(defaultIcon, for: UIControl.State())
            } else {
                ImageDownloader(imageSize).fromURI(token.image, completion: {
                    (image: UIImage) -> Void in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.image.setImage(image.addImagePadding(x: 30, y: 30), for: UIControl.State())
                    })
                })
            }
        } else {
            // Retrieve and use saved issuer -> icon mapping in User Defaults
            if let custIcon = icon.getCustomIcon(issuer: token.issuer, size: imageSize) {
                self.image.setImage(custIcon.iconImg.addImagePadding(x: 30, y: 30), for: UIControl.State())
                iconName = custIcon.name
                // Issuer matches an icon name brand
            } else if let faIcon = icon.getfaIconName(for: token.issuer) {
                let image = icon.getFontAwesomeIcon(faName: faIcon, faType: .brands, size: imageSize)
                self.image.setImage(image?.addImagePadding(x: 30, y: 30), for: UIControl.State())
                iconName = faIcon
            }
        }

        self.image.imageView?.backgroundColor = icon.getBackgroundColor(name: iconName)
        self.image.imageView?.layer.cornerRadius = 10
    }
}
