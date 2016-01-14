//
//  TextEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 17/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

private let kFontSizeInTextField = CGFloat(20)
private let kTextFieldHeight = CGFloat(40)
private let kTextLabelInitialMargin = CGFloat(40)
private let kMinimumFontSize = CGFloat(12.0)

@objc(IMGLYTextEditorViewControllerOptions) public class TextEditorViewControllerOptions: EditorViewControllerOptions {
    /// Use this closure to configure the text input field.
    /// Defaults to an empty implementation.
    public let textFieldConfigurationClosure: TextFieldConfigurationClosure

    /// Defaults to white.
    public let fontPreviewTextColor: UIColor

    /// An optional array of custom color values. The user can select a text color
    /// from the given values. If no colors are passed, a default color set is loaded.
    public let availableFontColors: [UIColor]?

    /// Enables/Disables the add text button. Defaults to true.
    public let canAddText: Bool

    /// Enables/Disables the delete text button. Defaults to true.
    public let canDeleteText: Bool

    /// Enables/Disables the pinch gesture, that allows resizing of the current text. Defaults to true.
    public let canModifyTextSize: Bool

    /// Enables/Disables text color changes through the bottom drawer. Defaults to true.
    public let canModifyTextColor: Bool

    /// Enables/Disables background color changes through the bottom drawer. Defaults to true.
    public let canModifyBackgroundColor: Bool

    /// Enables/Disables the bring to front option. Defaults to true.
    public let canBringToFront: Bool

    /// Enables/Disables font changes through the bottom drawer. Defaults to true.
    public let canModifyTextFont: Bool

    /// The name of the default Font. Defaults to 'Helvetica Neue'.
    public let defaultFontName: String

    /// The background color of the add text button. Defaults to petrol.
    public let addButtonBackgroundColor: UIColor

    /// The background color of the delete text button. Defaults to petrol.
    public let deleteButtonBackgroundColor: UIColor

    public convenience init() {
        self.init(builder: TextEditorViewControllerOptionsBuilder())
    }

    public init(builder: TextEditorViewControllerOptionsBuilder) {
        textFieldConfigurationClosure = builder.textFieldConfigurationClosure
        fontPreviewTextColor = builder.fontPreviewTextColor
        availableFontColors = builder.availableFontColors
        canAddText = builder.canAddText
        canDeleteText = builder.canDeleteText
        canModifyTextSize = builder.canModifyTextSize
        canModifyTextColor = builder.canModifyTextColor
        canModifyBackgroundColor = builder.canModifyBackgroundColor
        canBringToFront = builder.canBringToFront
        canModifyTextFont = builder.canModifyTextFont
        defaultFontName = builder.defaultFontName
        addButtonBackgroundColor = builder.addButtonBackgroundColor
        deleteButtonBackgroundColor = builder.deleteButtonBackgroundColor
        super.init(editorBuilder: builder)
    }
}

// swiftlint:disable type_name
@objc(IMGLYTextEditorViewControllerOptionsBuilder) public class TextEditorViewControllerOptionsBuilder: EditorViewControllerOptionsBuilder {
    // swiftlint:enable type_name

    /// Use this closure to configure the text input field.
    /// Defaults to an empty implementation.
    public lazy var textFieldConfigurationClosure: TextFieldConfigurationClosure = { _ in }

    /// Defaults to white.
    public var fontPreviewTextColor: UIColor = UIColor.whiteColor()

    /// An optional array of custom color values. The user can select a text color
    /// from the given values. If no colors are passed, a default color set is loaded.
    public var availableFontColors: [UIColor]?

    /// Enables/Disables the add text button. Defaults to true.
    public let canAddText = true

    /// Enables/Disables the delete text button. Defaults to true.
    public let canDeleteText = true

    /// Enables/Disables the pinch gesture, that allows resizing of the current text. Defaults to true.
    public var canModifyTextSize = true

    /// Enables/Disables color changes through the bottom drawer. Defaults to true.
    public var canModifyTextColor = true

    /// Enables/Disables background color changes through the bottom drawer. Defaults to true.
    public let canModifyBackgroundColor = true

    /// Enables/Disables the bring to front option. Defaults to true.
    public let canBringToFront = true

    /// Enables/Disables font changes through the bottom drawer. Defaults to true.
    public let canModifyTextFont = true

    /// The name of the default Font. Defaults to 'Helvetica Neue'.
    public let defaultFontName = "Helvetica Neue"

    /// The background color of the add text button. Defaults to petrol.
    public let addButtonBackgroundColor = UIColor(red:0, green:0.48, blue:0.56, alpha:0.6)

    /// The background color of the delete text button. Defaults to petrol.
    public let deleteButtonBackgroundColor = UIColor(red:0, green:0.48, blue:0.56, alpha:0.6)

    public override init() {
        super.init()

        /// Override inherited properties with default values
        self.title = NSLocalizedString("text-editor.title", tableName: nil, bundle: NSBundle(forClass: MainEditorViewController.self), value: "", comment: "")
    }
}

@objc(IMGLYTextEditorViewController) public class TextEditorViewController: SubEditorViewController {

    // MARK: - Properties

    private var textColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 1.0, alpha: 1.0)
    private var backgroundColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 1.0, alpha: 0.0)
    private var fontName = ""
    private var currentTextSize = CGFloat(0)
    private var maximumFontSize = CGFloat(0)
    private var panOffset = CGPointZero
    private var fontSizeAtPinchBegin = CGFloat(0)
    private var distanceAtPinchBegin = CGFloat(0)
    private var draggedView: UILabel?
    private var tempTextCopy = [Filter]()
    private var createNewText = false
    private var selectBackgroundColor = false

    public private(set) lazy var addTextButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "addText:", forControlEvents: .TouchUpInside)
        return button
    }()

    public private(set) lazy var deleteTextButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "deleteText:", forControlEvents: .TouchUpInside)
        return button
    }()

    public private(set) lazy var selectTextFontButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = ImageCaptionButton()
        button.textLabel.text = NSLocalizedString("text-editor.font", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "setTextFont:", forControlEvents: .TouchUpInside)
        return button
    }()

    public private(set) lazy var selectTextColorButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = ImageCaptionButton()
        button.textLabel.text = NSLocalizedString("text-editor.text-color", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "setTextColor:", forControlEvents: .TouchUpInside)
        return button
    }()

    public private(set) lazy var selectBackgroundColorButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = ImageCaptionButton()
        button.textLabel.text = NSLocalizedString("text-editor.background-color", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "setBackgroundColor:", forControlEvents: .TouchUpInside)
        return button
    }()

    public private(set) lazy var bringToFrontButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = ImageCaptionButton()
        button.textLabel.text = NSLocalizedString("text-editor.bring-to-front", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_custom", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "bringToFront:", forControlEvents: .TouchUpInside)
        return button
    }()


    public private(set) lazy var textClipView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    public private(set) lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.text = ""
        textField.textColor = self.textColor
        textField.backgroundColor = self.backgroundColor
        textField.clipsToBounds = false
        textField.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
        textField.returnKeyType = UIReturnKeyType.Done
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.options.textFieldConfigurationClosure(textField)
        return textField
    }()

    public private(set) lazy var fontSelectorView: FontSelectorView = {
        let selector = FontSelectorView()
        selector.translatesAutoresizingMaskIntoConstraints = false
        selector.selectorDelegate = self
        selector.fontPreviewTextColor = self.options.fontPreviewTextColor
        return selector
    }()

    public private(set) lazy var colorPickerView: ColorPickerView = {
        let selector = ColorPickerView()
        selector.translatesAutoresizingMaskIntoConstraints = false
        return selector
    }()

    private var textLabel = UILabel()

    private var blurredContainerView = UIVisualEffectView()

    // MARK: - Initializers

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - UIViewController

    override public func viewDidLoad() {
        super.viewDidLoad()

        InstanceFactory.fontImporter().importFonts()

        fontName = options.defaultFontName

        configureTextClipView()
        configureBottomButtons()
        configureAddButton()
        configureDeleteButton()
        configureGestureRecognizers()
        backupTexts()
        fixedFilterStack.textFilters.removeAll()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        rerenderPreviewWithoutText()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        textClipView.frame = view.convertRect(previewImageView.visibleImageFrame, fromView: previewImageView)
    }

    // MARK: - EditorViewController

    public override var options: TextEditorViewControllerOptions {
        return self.configuration.textEditorViewControllerOptions
    }

    // MARK: - SubEditorViewController

    public override func tappedDone(sender: UIBarButtonItem?) {
        let completeSize = textClipView.bounds.size
        let cropRect = self.fixedFilterStack.orientationCropFilter.cropRect
        for view in textClipView.subviews {
            if let label = view as? UILabel {
                print(label.center, completeSize)
                print(label.font)
                print(label.frame.size)
                let textFilter = InstanceFactory.textFilter()
                // swiftlint:disable force_cast
                textFilter.inputImage = self.previewImageView.image!.CIImage
                // swiftlint:enable force_cast
                textFilter.cropRect = cropRect
                var center = CGPoint(x: label.center.x / completeSize.width,
                    y: label.center.y / completeSize.height)
                center.x *= cropRect.width
                center.y *= cropRect.height
                center.x += cropRect.origin.x
                center.y += cropRect.origin.y
                textFilter.fontName = label.font.fontName
                textFilter.text = label.text ?? ""
                textFilter.initialFontSize = label.font.pointSize / previewImageView.visibleImageFrame.size.height
                textFilter.color = label.textColor
                textFilter.transform = label.transform
                textFilter.center = center
                fixedFilterStack.textFilters.append(textFilter)
            }
        }

        updatePreviewImageWithCompletion {
            super.tappedDone(sender)
        }
    }

    // MARK: - Configuration

    private func configureBottomButtons() {
        // Setup button container view
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonContainerView)
        bottomContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[buttonContainerView]|", options: [], metrics: nil, views: ["buttonContainerView": buttonContainerView]))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: buttonContainerView, attribute: .CenterX, relatedBy: .Equal, toItem: bottomContainerView, attribute: .CenterX, multiplier: 1, constant: 0))

        var views = [String: UIView]()
        var visualFormatString = ""
        if options.canModifyTextFont {
            views = viewsByAddingButton(selectTextFontButton, containerView: buttonContainerView, views: views)
            visualFormatString = visualFormatStringByAddingButton(selectTextFontButton, visualFormatString: visualFormatString)
        }
        if options.canModifyTextColor {
            views = viewsByAddingButton(selectTextColorButton, containerView: buttonContainerView, views: views)
            visualFormatString = visualFormatStringByAddingButton(selectTextColorButton, visualFormatString: visualFormatString)
        }
        if options.canModifyBackgroundColor {
            views = viewsByAddingButton(selectBackgroundColorButton, containerView: buttonContainerView, views: views)
            visualFormatString = visualFormatStringByAddingButton(selectBackgroundColorButton, visualFormatString: visualFormatString)
        }
        if options.canBringToFront {
            views = viewsByAddingButton(bringToFrontButton, containerView: buttonContainerView, views: views)
            visualFormatString = visualFormatStringByAddingButton(bringToFrontButton, visualFormatString: visualFormatString)
        }
        buttonContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|\(visualFormatString)|", options: [], metrics: [ "buttonWidth": 90 ], views: views))
    }

    private func configureAddButton() {
        let views: [String : AnyObject] = [
            "addTextButton" : addTextButton
        ]
        view.addSubview(addTextButton)
        addTextButton.clipsToBounds = false
        addTextButton.backgroundColor = options.addButtonBackgroundColor
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-20-[addTextButton]", options: [], metrics: [ "buttonWidth": 30 ], views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[addTextButton(40)]", options: [], metrics: nil, views: views))
        view.addConstraint(NSLayoutConstraint(item: addTextButton, attribute: .Bottom, relatedBy: .Equal, toItem: bottomContainerView, attribute: .Top, multiplier: 1, constant: -20))
    }

    private func configureDeleteButton() {
        let views: [String : AnyObject] = [
            "deleteTextButton" : deleteTextButton
        ]
        view.addSubview(deleteTextButton)
        deleteTextButton.clipsToBounds = false
        deleteTextButton.backgroundColor = options.addButtonBackgroundColor
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[deleteTextButton]-20-|", options: [], metrics: [ "buttonWidth": 30 ], views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[deleteTextButton(40)]", options: [], metrics: nil, views: views))
        view.addConstraint(NSLayoutConstraint(item: deleteTextButton, attribute: .Bottom, relatedBy: .Equal, toItem: bottomContainerView, attribute: .Top, multiplier: 1, constant: -20))
    }

    private func viewsByAddingButton(button: ImageCaptionButton, containerView: UIView, var views: [String: UIView]) -> ([String: UIView]) {
        let viewName = "_\(String(button.hash))"
        containerView.addSubview(button)
        views[viewName] = button
        containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[\(viewName)]|", options: [], metrics: nil, views: views))
        return views
    }

    private func visualFormatStringByAddingButton(button: ImageCaptionButton, var visualFormatString: String) -> (String) {
        let viewName = "_\(String(button.hash))"
        visualFormatString.appendContentsOf("[\(viewName)(==buttonWidth)]")
        return visualFormatString
    }

    private func configureTextClipView() {
        view.addSubview(textClipView)
    }

    private func configureTextLabel() {
        textClipView.addSubview(textLabel)
        textLabel.backgroundColor = self.backgroundColor
        textLabel.textColor = self.textColor
        textLabel.textAlignment = NSTextAlignment.Center
        textLabel.clipsToBounds = true
        textLabel.userInteractionEnabled = true
        // we set the rotation to 360 degree, so the transform anchor point is set to center
        textLabel.transform = CGAffineTransformRotate(textLabel.transform, CGFloat(M_PI) * 2.0)
    }

    private func configureTextField() {
        configureBlurredContainerView()
        blurredContainerView.contentView.addSubview(textField)

        let views = [
            "blurredContainerView" : blurredContainerView,
            "textField" : textField
        ]

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[blurredContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurredContainerView]|", options: [], metrics: nil, views: views))

        blurredContainerView.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-20-[textField]-20-|", options: [], metrics: nil, views: views))
        blurredContainerView.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-20-[textField]|", options: [], metrics: nil, views: views))

        blurredContainerView.alpha = 0.0
        UIView.animateWithDuration(0.3) {
            self.blurredContainerView.alpha = 1.0
        }
}

    private func configureFontSelectorView() {
        configureBlurredContainerView()
        blurredContainerView.contentView.addSubview(fontSelectorView)

        let views = [
            "blurredContainerView" : blurredContainerView,
            "fontSelectorView" : fontSelectorView
        ]

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[blurredContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurredContainerView]|", options: [], metrics: nil, views: views))

        blurredContainerView.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[fontSelectorView]|", options: [], metrics: nil, views: views))
        blurredContainerView.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[fontSelectorView]|", options: [], metrics: nil, views: views))

        blurredContainerView.alpha = 0.0
        UIView.animateWithDuration(0.3) {
            self.blurredContainerView.alpha = 1.0
        }
    }

    private func configureColorPickerView() {
        configureBlurredContainerView()
        blurredContainerView.contentView.addSubview(colorPickerView)
        colorPickerView.initialColor = selectBackgroundColor ? textLabel.backgroundColor : textLabel.textColor
        colorPickerView.pickerDelegate = self

        let views = [
            "blurredContainerView" : blurredContainerView,
            "colorPickerView" : colorPickerView
        ]

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[blurredContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurredContainerView]|", options: [], metrics: nil, views: views))

        blurredContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[colorPickerView]|", options: [], metrics: nil, views: views))
        blurredContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[colorPickerView]|", options: [], metrics: nil, views: views))
        blurredContainerView.alpha = 0.0
        UIView.animateWithDuration(0.3) {
            self.blurredContainerView.alpha = 1.0
        }
    }

    private func configureBlurredContainerView() {
        let blurEffect = UIBlurEffect(style: .Dark)
        blurredContainerView = UIVisualEffectView(effect: blurEffect)
        blurredContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurredContainerView)
    }

    private func configureGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        textClipView.addGestureRecognizer(panGestureRecognizer)

        if options.canModifyTextSize {
            let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
            pinchGestureRecognizer.delegate = self
            textClipView.addGestureRecognizer(pinchGestureRecognizer)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        tapGestureRecognizer.delegate = self
        textClipView.addGestureRecognizer(tapGestureRecognizer)

        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: "handleRotate:")
        rotationGestureRecognizer.delegate = self
        textClipView.addGestureRecognizer(rotationGestureRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressRecognizer.minimumPressDuration = 2
        textClipView.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - Button Handling

    @objc private func addText(sender: UIButton) {
        navigationItem.rightBarButtonItem?.enabled = false
        createNewText = true
        configureTextField()
        textField.text = ""
        textField.becomeFirstResponder()
    }

    @objc private func deleteText(sender: UIButton) {
        if textLabel.layer.borderWidth > 0 {
            textLabel.removeFromSuperview()
        }
    }

    @objc private func setTextFont(sender: ImageCaptionButton) {
        navigationItem.rightBarButtonItem?.enabled = false
        configureFontSelectorView()
    }

    @objc private func setTextColor(sender: ImageCaptionButton) {
        navigationItem.rightBarButtonItem?.enabled = false
        selectBackgroundColor = false
        configureColorPickerView()
    }

    @objc private func setBackgroundColor(sender: ImageCaptionButton) {
        navigationItem.rightBarButtonItem?.enabled = false
        selectBackgroundColor = true
        configureColorPickerView()
    }

    @objc private func bringToFront(sender: ImageCaptionButton) {
        if textLabel.layer.borderWidth > 0 {
            textClipView.bringSubviewToFront(textLabel)
        }
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.locationInView(textClipView)
        let translation = recognizer.translationInView(textClipView)
        switch recognizer.state {
        case .Began:
            draggedView = textClipView.hitTest(location, withEvent: nil) as? UILabel
            if let draggedView = draggedView {
                unSelectTextLabel(textLabel)
                textLabel = draggedView
                selectTextLabel(textLabel)
            }
        case .Changed:
            if let draggedView = draggedView {
                draggedView.center = CGPoint(x: draggedView.center.x + translation.x, y: draggedView.center.y + translation.y)
            }
            recognizer.setTranslation(CGPointZero, inView: textClipView)
       case .Cancelled, .Ended:
            draggedView = nil
        default:
            break
       }
    }

    @objc private func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.numberOfTouches() == 2 {
            let point1 = recognizer.locationOfTouch(0, inView:textClipView)
            let point2 = recognizer.locationOfTouch(1, inView:textClipView)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let scale = recognizer.scale

            switch recognizer.state {
            case .Began:
                if draggedView == nil {
                    draggedView = textClipView.hitTest(midpoint, withEvent: nil) as? UILabel
                }

                if let draggedView = draggedView {
                    unSelectTextLabel(textLabel)
                    textLabel = draggedView
                    selectTextLabel(textLabel)
                }
            case .Changed:
                if let draggedView =  draggedView {
                    currentTextSize = draggedView.font.pointSize
                    currentTextSize *= scale
                    draggedView.font = UIFont(name: draggedView.font.fontName, size: currentTextSize)
                    draggedView.sizeToFit()
                }
                recognizer.scale = 1
            case .Cancelled, .Ended:
                draggedView = nil
            default:
                break
            }
        }
    }

    @objc private func handleRotate(recognizer: UIRotationGestureRecognizer) {
        if recognizer.numberOfTouches() == 2 {
            let point1 = recognizer.locationOfTouch(0, inView: textClipView)
            let point2 = recognizer.locationOfTouch(1, inView: textClipView)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let rotation = recognizer.rotation

            switch recognizer.state {
            case .Began:
                if draggedView == nil {
                    draggedView = textClipView.hitTest(midpoint, withEvent: nil) as? UILabel
                }

                if let draggedView = draggedView {
                    unSelectTextLabel(textLabel)
                    textLabel = draggedView
                    selectTextLabel(textLabel)
                }
            case .Changed:
                if let draggedView = draggedView {
                    draggedView.transform = CGAffineTransformRotate(draggedView.transform, rotation)
                }

                recognizer.rotation = 0
            case .Cancelled, .Ended:
                draggedView = nil
            default:
                break
            }
        }
    }

    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.locationInView(textClipView)
        draggedView = textClipView.hitTest(location, withEvent: nil) as? UILabel
        unSelectTextLabel(textLabel)
        if let draggedView = draggedView {
            textLabel = draggedView
            currentTextSize = textLabel.font.pointSize
            selectTextLabel(textLabel)
        }
    }

    @objc private func handleLongPress(recognizer: UITapGestureRecognizer) {
        let location = recognizer.locationInView(textClipView)
        draggedView = textClipView.hitTest(location, withEvent: nil) as? UILabel
        if recognizer.state == .Began {
            if let draggedView = draggedView {
                textLabel = draggedView
                if textLabel.layer.borderWidth > 0 {
                    createNewText = false
                    configureTextField()
                    textField.text = textLabel.text
                    textField.becomeFirstResponder()
                }
            }
        }
    }
    // MARK: - Helpers

    private func hideBlurredContainer() {
        UIView.animateWithDuration(0.3, animations: {
            self.blurredContainerView.alpha = 0.0
            }, completion: {
                (value: Bool) in
                self.navigationItem.rightBarButtonItem?.enabled = true
                self.blurredContainerView.removeFromSuperview()
        })
    }

    private func calculateInitialFontSize() {
        // swiftlint:disable force_cast
       let customParagraphStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        // swiftlint:enable force_cast
        customParagraphStyle.lineBreakMode = .ByClipping

        if let text = textLabel.text {
            currentTextSize = 1.0
            var size = CGSizeZero
            if !text.isEmpty {
                repeat {
                    currentTextSize += 1.0
                    if let font = UIFont(name: fontName, size: currentTextSize) {
                        size = text.sizeWithAttributes([ NSFontAttributeName: font,  NSParagraphStyleAttributeName:customParagraphStyle])
                    }
                } while ((size.width < (textClipView.frame.size.width - kTextLabelInitialMargin)) && (size.height < (textClipView.frame.size.height - kTextLabelInitialMargin)))
            }
        }
    }

    private func setInitialTextLabelSize() {
        calculateInitialFontSize()
        textLabel.font = UIFont(name: fontName, size: currentTextSize)
        textLabel.sizeToFit()
        textLabel.frame.origin.x = kTextLabelInitialMargin / 2.0 - textClipView.frame.origin.x
        textLabel.frame.origin.y = -textLabel.frame.size.height / 2.0 + textClipView.frame.height / 2.0
    }

    private func calculateNewFontSizeBasedOnDistanceBetweenPoint(point1: CGPoint, and point2: CGPoint) -> CGFloat {
        let diffX = point1.x - point2.x
        let diffY = point1.y - point2.y
        return sqrt(diffX * diffX + diffY  * diffY)
    }

    private func selectTextLabel(label: UILabel) {
        label.layer.borderColor = UIColor.whiteColor().CGColor
        label.layer.borderWidth = 1.0
    }

    private func unSelectTextLabel(label: UILabel) {
        label.layer.borderWidth = 0
    }

    // MARK: - text object restore

    private func rerenderPreviewWithoutText() {
        updatePreviewImageWithCompletion { () -> (Void) in
            self.addTextsFromTextFilters(self.tempTextCopy)
        }
    }

    private func backupTexts() {
        tempTextCopy = fixedFilterStack.textFilters
    }

    /*
    * in this method we do some calculations to re calculate the
    * sticker position in relation to the crop region.
    * Therefore we calculte the position and size within the non-cropped image
    * and apply the translation and scaling that comes with cropping in relation
    * to the full image.
    * When we are done we must revoke that extra transformation.
    */
    private func addTextsFromTextFilters(textFilters: [Filter]) {
        for element in textFilters {
            guard let textFilter = element as? TextFilter else {
                return
            }
            let label = UILabel()
            label.userInteractionEnabled = true
            let cropRect = self.fixedFilterStack.orientationCropFilter.cropRect
            var completeSize = previewImageView.visibleImageFrame.size
            completeSize.width *= 1.0 / cropRect.width
            completeSize.height *= 1.0 / cropRect.height
            label.font = UIFont(name: textFilter.fontName, size: textFilter.initialFontSize * previewImageView.visibleImageFrame.size.height)
            label.text = textFilter.text
            label.sizeToFit()
            label.transform = textFilter.transform

            var center = CGPoint(x: textFilter.center.x * completeSize.width,
                y: textFilter.center.y * completeSize.height)
            center.x -= cropRect.origin.x
            center.y -= cropRect.origin.y
            center.x /= cropRect.width
            center.y /= cropRect.height

            label.center = center
            print(center, completeSize)
            print(label.frame.size)
            label.clipsToBounds = false
            label.textColor = textFilter.color
            textClipView.addSubview(label)
        }
    }
}

// MARK:- extensions

extension TextEditorViewController: TextColorSelectorViewDelegate {
    public func textColorSelectorView(selectorView: TextColorSelectorView, didSelectColor color: UIColor) {
        textColor = color
        textField.textColor = color
        textLabel.textColor = color
    }
}

extension TextEditorViewController: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }

    public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        hideBlurredContainer()
        if createNewText {
            unSelectTextLabel(textLabel)
            textLabel = UILabel()
            configureTextLabel()
            textLabel.text = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            setInitialTextLabelSize()
            textClipView.bringSubviewToFront(textLabel)
        } else {
            textLabel.text = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            textLabel.sizeToFit()
        }
        selectTextLabel(textLabel)
        navigationItem.rightBarButtonItem?.enabled = true
        return true
    }

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension TextEditorViewController: FontSelectorViewDelegate {
    public func fontSelectorView(fontSelectorView: FontSelectorView, didSelectFontWithName fontName: String) {
        hideBlurredContainer()
        self.fontName = fontName
        if textLabel.layer.borderWidth > 0 {
            textLabel.font = UIFont(name: fontName, size: currentTextSize)
            textLabel.sizeToFit()
        }
    }
}

extension TextEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) || (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        return false
    }
}

extension TextEditorViewController: ColorPickerViewDelegate {
    public func colorPicked(colorPickerView: ColorPickerView, didPickColor color: UIColor) {
        if selectBackgroundColor {
            textLabel.backgroundColor = color
        } else {
            textLabel.textColor = color
        }
        hideBlurredContainer()
    }

    public func canceledColorPicking(colorPickerView: ColorPickerView) {
        hideBlurredContainer()
    }
}
