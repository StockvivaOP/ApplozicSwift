//
//  SVALKMarqueeView.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 21/2/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import Foundation
import UIKit

public protocol SVALKMarqueeViewDelegate {
    func marqueeListDisplayCompleted()
    func viewDidClosed()
}

public class SVALKMarqueeView: UIView {
    
    private var currentMessageIndex:Int = 0
    private var isAnimationRunning = false
    private let font:UIFont = UIFont.systemFont(ofSize: 13.0)
    private let durationSecondOfDisplay = 5.0
    private var closeButtonImage:UIImage? = UIImage(named: "sv_icon_circle_close", in: Bundle.applozic, compatibleWith: nil)
    
    public var messages:[String] = []
    public var delegate:SVALKMarqueeViewDelegate?
    
    //ui
    private var viewContainer = UIView()
    private var btnClose:UIButton = UIButton(type: UIButton.ButtonType.custom)
    private var labMessageOne = UILabel()
    private var labMessageTwo = UILabel()
    //anim
    private var displayContentAnim:UIViewPropertyAnimator!
    private var switchContentAnim:UIViewPropertyAnimator!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initView()
    }
    
    private func initView(){
        let _defaultMinSize = CGSize(width: 275.0, height: 27.0)
        let _closeButtonSize = CGSize(width: 27.0, height: 27.0)
        
        //self view
        if self.frame.width < _defaultMinSize.width {
            self.frame.size.width = _defaultMinSize.width
        }
        if self.frame.height < _defaultMinSize.height {
            self.frame.size.height = _defaultMinSize.height
        }
        self.clipsToBounds = true
        self.backgroundColor = UIColor.init(red: 42.0/255.0, green: 29.0/255.0, blue: 48.0/255.0, alpha: 0.9)
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.layer.borderWidth = 3.0
        self.layer.borderColor = UIColor.init(red: 118.0/255.0, green: 85.0/255.0, blue: 255.0/255.0, alpha: 0.9).cgColor
       
        //view container
        let _widthContainerView = self.frame.size.width - 14.0 - 2.0 - _closeButtonSize.width - 5.0
        let _containerViewSize = CGSize(width: _widthContainerView, height: 19.0)
        self.viewContainer.clipsToBounds = true
        self.viewContainer.backgroundColor = UIColor.clear
        self.viewContainer.frame = CGRect(x: 14.0, y: 4,
                                          width: _containerViewSize.width, height: _containerViewSize.height)
        
        //display label
        self.labMessageOne.font = self.font
        self.labMessageOne.textAlignment = .center
        self.labMessageOne.textColor = UIColor.white
        self.labMessageOne.frame = CGRect(x: 0,
                                          y: 0,
                                          width: self.viewContainer.frame.size.width,
                                          height: self.viewContainer.frame.size.height)
        self.labMessageTwo.font = self.font
        self.labMessageTwo.textAlignment = .center
        self.labMessageTwo.textColor = UIColor.white
        self.labMessageTwo.frame = CGRect(x: 0,
                                          y: self.viewContainer.frame.size.height,
                                          width: self.viewContainer.frame.size.width,
                                          height: self.viewContainer.frame.size.height)
        
        //button
        self.btnClose.frame = CGRect(x: self.frame.size.width - _closeButtonSize.width - 5.0, y: 0,
                                     width: _closeButtonSize.width, height: _closeButtonSize.height)
        self.btnClose.imageEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        self.btnClose.setTitle("", for: .normal)
        self.btnClose.backgroundColor = UIColor.clear
        self.btnClose.setImage(self.closeButtonImage, for: .normal)
        self.btnClose.addTarget(self, action: #selector(closeButtonTouchUpInside(_:)), for: .touchUpInside)
        
        //add into view
        self.addSubview(self.viewContainer)
        self.addSubview(self.btnClose)
        self.viewContainer.addSubview(self.labMessageOne)
        self.viewContainer.addSubview(self.labMessageTwo)
    }
    
    public func closeView(){
        self.closeButtonTouchUpInside(self.btnClose)
    }
    
    private func reset(){
        self.isAnimationRunning = false
        self.currentMessageIndex = 0
        self.clearLabelContent(label: self.labMessageOne)
        self.clearLabelContent(label: self.labMessageTwo)
        //reset label position
        self.labMessageOne.frame = CGRect(x: 0,
                                          y: 0,
                                          width: self.viewContainer.frame.size.width,
                                          height: self.viewContainer.frame.size.height)
        self.labMessageTwo.frame = CGRect(x: 0,
                                          y: self.viewContainer.frame.size.height,
                                          width: self.viewContainer.frame.size.width,
                                          height: self.viewContainer.frame.size.height)
    }
    
    private func clear(){
        self.reset()
        self.messages.removeAll()
    }
}

//MARK: - animate
extension SVALKMarqueeView {
    public func startAnim(){
        if self.messages.count == 0 {
            self.closeView()
            return
        }
        self.isHidden = false
        //load message
        self.loadNextContentToLabel(label: self.labMessageOne)
        self.loadNextContentToLabel(label: self.labMessageTwo)
        
        //start animation
        self.isAnimationRunning = true
        self.startDisplayContentAnimation()
    }
    
    public func stopAnim(){
        self.isAnimationRunning = false
        if self.displayContentAnim != nil && self.displayContentAnim.isRunning {
            self.displayContentAnim.stopAnimation(true)
        }
        if self.switchContentAnim != nil && self.switchContentAnim.isRunning {
            self.switchContentAnim.stopAnimation(true)
        }
        self.reset()
    }
    
    private func startDisplayContentAnimation(){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.displayContentAnim = UIViewPropertyAnimator(duration: self.durationSecondOfDisplay, curve: UIView.AnimationCurve.linear, animations: {
                if self.labMessageTwo.frame.minY == 0 {
                    self.labMessageTwo.frame =
                        self.labMessageTwo.frame.offsetBy(
                            dx: self.viewContainer.frame.size.width - self.labMessageTwo.frame.size.width,
                            dy: 0)
                }else{
                    self.labMessageOne.frame =
                        self.labMessageOne.frame.offsetBy(
                            dx: self.viewContainer.frame.size.width - self.labMessageOne.frame.size.width,
                            dy: 0)
                }
            })
            self.displayContentAnim.isInterruptible = true
            self.displayContentAnim.addCompletion { (viewPosition) in
                self.startSwitchContentAnimation()
            }
            if self.isAnimationRunning {
                self.displayContentAnim.startAnimation()
            }
        }
    }
    
    private func startSwitchContentAnimation(){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.switchContentAnim = UIViewPropertyAnimator(duration: 0.5, curve: UIView.AnimationCurve.linear, animations: {
                if self.labMessageTwo.frame.minY == 0 {
                    self.labMessageOne.frame.origin.y = 0
                    self.labMessageTwo.frame.origin.y = self.viewContainer.frame.size.height * -1
                }else{
                    self.labMessageOne.frame.origin.y = self.viewContainer.frame.size.height * -1
                    self.labMessageTwo.frame.origin.y = 0
                }
            })
            self.switchContentAnim.isInterruptible = true
            self.switchContentAnim.addCompletion { (viewPosition) in
                if self.labMessageTwo.frame.minY < 0 {
                    self.labMessageTwo.frame.origin.x = 0
                    self.labMessageTwo.frame.origin.y = self.viewContainer.frame.size.height
                    self.loadNextContentToLabel(label: self.labMessageTwo)
                }else{
                    self.labMessageOne.frame.origin.x = 0
                    self.labMessageOne.frame.origin.y = self.viewContainer.frame.size.height
                    self.loadNextContentToLabel(label: self.labMessageOne)
                }
                //start loop animation
                self.startDisplayContentAnimation()
            }
            if self.isAnimationRunning {
                self.switchContentAnim.startAnimation()
            }
        }
    }
}

//MARK: - labe content setup
extension SVALKMarqueeView {
    public func addMessage(messageList:[String]?){
        guard let _list = messageList, _list.count > 0 else {
            return
        }
        self.messages.append(contentsOf: _list)
    }
    
    private func loadNextContentToLabel(label:UILabel){
        let _getIndex = self.currentMessageIndex
        if _getIndex < self.messages.count {
            let _message = self.messages[_getIndex]
            self.setLabelContent(label: label, message: _message)
            self.currentMessageIndex = _getIndex + 1
        }
        //reset next and call
        if self.currentMessageIndex >= self.messages.count {
            self.currentMessageIndex = 0//reset
            if self.messages.count > 0 {
                self.delegate?.marqueeListDisplayCompleted()
            }
        }
    }
    
    private func setLabelContent(label:UILabel, message:String){
        let _contentMessage = "<div style=\"font-family:'-apple-system','HelveticaNeue';font-size:\(self.font.pointSize);color: white;text-align:center;font-weight: normal;\" >\(message)</div>"
        if let _dataImage = _contentMessage.data(using: String.Encoding.utf8),
            let _htmlString = try? NSMutableAttributedString(data: _dataImage, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil) {
            let _resultAttStr = NSMutableAttributedString(attributedString: _htmlString)
            label.attributedText = _resultAttStr
            //update size
            let _size = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: self.viewContainer.frame.size.height) )
            label.frame.size.width = max(self.viewContainer.frame.size.width, _size.width)
            label.frame.size.height = self.viewContainer.frame.size.height
        }else{
            label.attributedText = nil
        }
    }
    
    private func clearLabelContent(label:UILabel){
        label.attributedText = nil
    }
    
    public class func getHtmlFormatImage(url:String) -> String {
        return "<img style=\"width:15px;height:15px;\" src='\(url)'>"
    }
    
}

//MARK: - button control
extension SVALKMarqueeView {
    @objc private func closeButtonTouchUpInside(_ sender: Any) {
        self.stopAnim()
        self.clear()
        self.isHidden = true
        self.delegate?.viewDidClosed()
    }
}

