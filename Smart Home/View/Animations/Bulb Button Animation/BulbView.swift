//
// BulbView.swift
// Generated by Core Animator version 1.5.2 on 27/01/18.
//
// DO NOT MODIFY THIS FILE. IT IS AUTO-GENERATED AND WILL BE OVERWRITTEN
//

import UIKit

private class _BulbPassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if subview.point(inside: convert(point, to: subview), with: event) { return true }
        }
        return false
    }
}

@IBDesignable
class BulbView : UIView, CAAnimationDelegate, AnimationViewProtocol {


	var animationCompletions = Dictionary<CAAnimation, (Bool) -> Void>()
	var viewsByName: [String : UIView]!

	// - MARK: Life Cycle

	convenience init() {
		self.init(frame: CGRect(x: 0, y: 0, width: 65, height: 105))
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.setupHierarchy()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.setupHierarchy()
	}

	// - MARK: Scaling

	override func layoutSubviews() {
		super.layoutSubviews()

		if let scalingView = self.viewsByName["__scaling__"] {
			var xScale = self.bounds.size.width / scalingView.bounds.size.width
			var yScale = self.bounds.size.height / scalingView.bounds.size.height
			switch contentMode {
			case .scaleToFill:
				break
			case .scaleAspectFill:
				let scale = max(xScale, yScale)
				xScale = scale
				yScale = scale
			default:
				let scale = min(xScale, yScale)
				xScale = scale
				yScale = scale
			}
			scalingView.transform = CGAffineTransform(scaleX: xScale, y: yScale)
			scalingView.center = CGPoint(x:self.bounds.midX, y:self.bounds.midY)
		}
	}

	// - MARK: Setup

	func setupHierarchy() {
		var viewsByName: [String : UIView] = [:]
		let bundle = Bundle(for:type(of: self))
		let __scaling__ = UIView()
		__scaling__.bounds = CGRect(x:0, y:0, width:65, height:105)
		__scaling__.center = CGPoint(x:32.5, y:52.5)
		__scaling__.clipsToBounds = true
		self.addSubview(__scaling__)
		viewsByName["__scaling__"] = __scaling__

		let bulb__root = _BulbPassthroughView()
		let bulb__xScale = _BulbPassthroughView()
		let bulb__yScale = _BulbPassthroughView()
		let bulb = UIImageView()
		let imgBulb = UIImage(named:"bulb.png", in: bundle, compatibleWith: nil)
		if imgBulb == nil {
			print("** Warning: Could not create image from 'bulb.png'")
		}
		bulb.image = imgBulb
		bulb.contentMode = .center
		bulb.bounds = CGRect(x:0, y:0, width:57.0, height:75.0)
		bulb__root.layer.position = CGPoint(x:32.325, y:63.692)
		bulb__xScale.transform = CGAffineTransform(scaleX: 1.00, y: 1.00)
		bulb__yScale.transform = CGAffineTransform(scaleX: 1.00, y: 1.00)
		bulb__root.transform = CGAffineTransform(rotationAngle: 0.000)
		bulb__root.addSubview(bulb__xScale)
		bulb__xScale.addSubview(bulb__yScale)
		bulb__yScale.addSubview(bulb)
		__scaling__.addSubview(bulb__root)
		viewsByName["Bulb__root"] = bulb__root
		viewsByName["Bulb__xScale"] = bulb__xScale
		viewsByName["Bulb__yScale"] = bulb__yScale
		viewsByName["Bulb"] = bulb

		let lightRays__root = _BulbPassthroughView()
		let lightRays__xScale = _BulbPassthroughView()
		let lightRays__yScale = _BulbPassthroughView()
		let lightRays = UIImageView()
		let imgLightRays = UIImage(named:"Light Rays.png", in: bundle, compatibleWith: nil)
		if imgLightRays == nil {
			print("** Warning: Could not create image from 'Light Rays.png'")
		}
		lightRays.image = imgLightRays
		lightRays.contentMode = .center
		lightRays.bounds = CGRect(x:0, y:0, width:62.0, height:37.0)
		lightRays__root.layer.position = CGPoint(x:32.325, y:17.497)
		lightRays__xScale.transform = CGAffineTransform(scaleX: 0.91, y: 1.00)
		lightRays__yScale.transform = CGAffineTransform(scaleX: 1.00, y: 0.91)
		lightRays__root.transform = CGAffineTransform(rotationAngle: 0.000)
		lightRays__root.addSubview(lightRays__xScale)
		lightRays__xScale.addSubview(lightRays__yScale)
		lightRays__yScale.addSubview(lightRays)
		__scaling__.addSubview(lightRays__root)
		viewsByName["Light Rays__root"] = lightRays__root
		viewsByName["Light Rays__xScale"] = lightRays__xScale
		viewsByName["Light Rays__yScale"] = lightRays__yScale
		viewsByName["Light Rays"] = lightRays

		let lightRaysMask__root = _BulbPassthroughView()
		let lightRaysMask__xScale = _BulbPassthroughView()
		let lightRaysMask__yScale = _BulbPassthroughView()
		let lightRaysMask = UIImageView()
		let imgGradient2 = UIImage(named:"gradient2.png", in: bundle, compatibleWith: nil)
		if imgGradient2 == nil {
			print("** Warning: Could not create image from 'gradient2.png'")
		}
		lightRaysMask.image = imgGradient2
		lightRaysMask.contentMode = .center
		lightRaysMask.bounds = CGRect(x:0, y:0, width:185.0, height:118.0)
		lightRaysMask__root.layer.position = CGPoint(x:31.268, y:70.226)
		lightRaysMask__xScale.transform = CGAffineTransform(scaleX: 0.39, y: 1.00)
		lightRaysMask__yScale.transform = CGAffineTransform(scaleX: 1.00, y: 0.37)
		lightRaysMask__root.transform = CGAffineTransform(rotationAngle: 3.142)
		lightRaysMask__root.addSubview(lightRaysMask__xScale)
		lightRaysMask__xScale.addSubview(lightRaysMask__yScale)
		lightRaysMask__yScale.addSubview(lightRaysMask)
		lightRays.mask = lightRaysMask__root
		viewsByName["Light Rays_mask__root"] = lightRaysMask__root
		viewsByName["Light Rays_mask__xScale"] = lightRaysMask__xScale
		viewsByName["Light Rays_mask__yScale"] = lightRaysMask__yScale
		viewsByName["Light Rays_mask"] = lightRaysMask

		self.viewsByName = viewsByName
	}

	// - MARK: removeLightRays

    func turnOffAnimation() {
		addRemoveLightRaysAnimation(beginTime: 0, fillMode: kCAFillModeBoth, removedOnCompletion: false, completion: nil)
	}

	func addRemoveLightRaysAnimation(completion: ((Bool) -> Void)?) {
		addRemoveLightRaysAnimation(beginTime: 0, fillMode: kCAFillModeBoth, removedOnCompletion: false, completion: completion)
	}

	func addRemoveLightRaysAnimation(removedOnCompletion: Bool) {
		addRemoveLightRaysAnimation(beginTime: 0, fillMode: removedOnCompletion ? kCAFillModeRemoved : kCAFillModeBoth, removedOnCompletion: removedOnCompletion, completion: nil)
	}

	func addRemoveLightRaysAnimation(removedOnCompletion: Bool, completion: ((Bool) -> Void)?) {
		addRemoveLightRaysAnimation(beginTime: 0, fillMode: removedOnCompletion ? kCAFillModeRemoved : kCAFillModeBoth, removedOnCompletion: removedOnCompletion, completion: completion)
	}

	func addRemoveLightRaysAnimation(beginTime: CFTimeInterval, fillMode: String, removedOnCompletion: Bool, completion: ((Bool) -> Void)?) {
		let linearTiming = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		if let complete = completion {
			let representativeAnimation = CABasicAnimation(keyPath: "not.a.real.key")
			representativeAnimation.duration = 0.250
			representativeAnimation.delegate = self
			self.layer.add(representativeAnimation, forKey: "RemoveLightRays")
			self.animationCompletions[layer.animation(forKey: "RemoveLightRays")!] = complete
		}

		let bulbScaleXAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
		bulbScaleXAnimation.duration = 0.250
		bulbScaleXAnimation.values = [1.000, 0.900, 1.000] as [Float]
		bulbScaleXAnimation.keyTimes = [0.000, 0.400, 1.000] as [NSNumber]
		bulbScaleXAnimation.timingFunctions = [linearTiming, linearTiming]
		bulbScaleXAnimation.beginTime = beginTime
		bulbScaleXAnimation.fillMode = fillMode
		bulbScaleXAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Bulb__xScale"]?.layer.add(bulbScaleXAnimation, forKey:"removeLightRays_ScaleX")

		let bulbScaleYAnimation = CAKeyframeAnimation(keyPath: "transform.scale.y")
		bulbScaleYAnimation.duration = 0.250
		bulbScaleYAnimation.values = [1.000, 0.900, 1.000] as [Float]
		bulbScaleYAnimation.keyTimes = [0.000, 0.400, 1.000] as [NSNumber]
		bulbScaleYAnimation.timingFunctions = [linearTiming, linearTiming]
		bulbScaleYAnimation.beginTime = beginTime
		bulbScaleYAnimation.fillMode = fillMode
		bulbScaleYAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Bulb__yScale"]?.layer.add(bulbScaleYAnimation, forKey:"removeLightRays_ScaleY")

		let lightRaysMaskImageContentsAnimation = CAKeyframeAnimation(keyPath: "contents")
		lightRaysMaskImageContentsAnimation.duration = 0.250
		lightRaysMaskImageContentsAnimation.values = [UIImage(named: "square.png", in: Bundle(for:type(of: self)), compatibleWith: nil)!.cgImage!, UIImage(named: "square.png", in: Bundle(for:type(of: self)), compatibleWith: nil)!.cgImage!] as [CGImage]
		lightRaysMaskImageContentsAnimation.keyTimes = [0.000, 1.000] as [NSNumber]
		lightRaysMaskImageContentsAnimation.timingFunctions = [linearTiming]
		lightRaysMaskImageContentsAnimation.beginTime = beginTime
		lightRaysMaskImageContentsAnimation.fillMode = fillMode
		lightRaysMaskImageContentsAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Light Rays_mask"]?.layer.add(lightRaysMaskImageContentsAnimation, forKey:"removeLightRays_ImageContents")

		let lightRaysMaskTranslationYAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
		lightRaysMaskTranslationYAnimation.duration = 0.250
		lightRaysMaskTranslationYAnimation.values = [-40.000, -35.000, 13.000, 13.000] as [Float]
		lightRaysMaskTranslationYAnimation.keyTimes = [0.000, 0.040, 0.760, 1.000] as [NSNumber]
		lightRaysMaskTranslationYAnimation.timingFunctions = [linearTiming, linearTiming, linearTiming]
		lightRaysMaskTranslationYAnimation.beginTime = beginTime
		lightRaysMaskTranslationYAnimation.fillMode = fillMode
		lightRaysMaskTranslationYAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Light Rays_mask__root"]?.layer.add(lightRaysMaskTranslationYAnimation, forKey:"removeLightRays_TranslationY")
	}

	func removeRemoveLightRaysAnimation() {
		self.layer.removeAnimation(forKey: "RemoveLightRays")
		self.viewsByName["Bulb__xScale"]?.layer.removeAnimation(forKey: "removeLightRays_ScaleX")
		self.viewsByName["Bulb__yScale"]?.layer.removeAnimation(forKey: "removeLightRays_ScaleY")
		self.viewsByName["Light Rays_mask"]?.layer.removeAnimation(forKey: "removeLightRays_ImageContents")
		self.viewsByName["Light Rays_mask__root"]?.layer.removeAnimation(forKey: "removeLightRays_TranslationY")
	}

	// - MARK: showLightRays

    func turnOnAnimation() {
		addShowLightRaysAnimation(beginTime: 0, fillMode: kCAFillModeBoth, removedOnCompletion: false, completion: nil)
	}

	func addShowLightRaysAnimation(completion: ((Bool) -> Void)?) {
		addShowLightRaysAnimation(beginTime: 0, fillMode: kCAFillModeBoth, removedOnCompletion: false, completion: completion)
	}

	func addShowLightRaysAnimation(removedOnCompletion: Bool) {
		addShowLightRaysAnimation(beginTime: 0, fillMode: removedOnCompletion ? kCAFillModeRemoved : kCAFillModeBoth, removedOnCompletion: removedOnCompletion, completion: nil)
	}

	func addShowLightRaysAnimation(removedOnCompletion: Bool, completion: ((Bool) -> Void)?) {
		addShowLightRaysAnimation(beginTime: 0, fillMode: removedOnCompletion ? kCAFillModeRemoved : kCAFillModeBoth, removedOnCompletion: removedOnCompletion, completion: completion)
	}

	func addShowLightRaysAnimation(beginTime: CFTimeInterval, fillMode: String, removedOnCompletion: Bool, completion: ((Bool) -> Void)?) {
		let linearTiming = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		if let complete = completion {
			let representativeAnimation = CABasicAnimation(keyPath: "not.a.real.key")
			representativeAnimation.duration = 0.250
			representativeAnimation.delegate = self
			self.layer.add(representativeAnimation, forKey: "ShowLightRays")
			self.animationCompletions[layer.animation(forKey: "ShowLightRays")!] = complete
		}

		let bulbScaleXAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
		bulbScaleXAnimation.duration = 0.250
		bulbScaleXAnimation.values = [1.000, 1.100, 1.000] as [Float]
		bulbScaleXAnimation.keyTimes = [0.000, 0.400, 1.000] as [NSNumber]
		bulbScaleXAnimation.timingFunctions = [linearTiming, linearTiming]
		bulbScaleXAnimation.beginTime = beginTime
		bulbScaleXAnimation.fillMode = fillMode
		bulbScaleXAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Bulb__xScale"]?.layer.add(bulbScaleXAnimation, forKey:"showLightRays_ScaleX")

		let bulbScaleYAnimation = CAKeyframeAnimation(keyPath: "transform.scale.y")
		bulbScaleYAnimation.duration = 0.250
		bulbScaleYAnimation.values = [1.000, 1.100, 1.000] as [Float]
		bulbScaleYAnimation.keyTimes = [0.000, 0.400, 1.000] as [NSNumber]
		bulbScaleYAnimation.timingFunctions = [linearTiming, linearTiming]
		bulbScaleYAnimation.beginTime = beginTime
		bulbScaleYAnimation.fillMode = fillMode
		bulbScaleYAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Bulb__yScale"]?.layer.add(bulbScaleYAnimation, forKey:"showLightRays_ScaleY")

		let lightRaysMaskImageContentsAnimation = CAKeyframeAnimation(keyPath: "contents")
		lightRaysMaskImageContentsAnimation.duration = 0.250
		lightRaysMaskImageContentsAnimation.values = [UIImage(named: "gradient2.png", in: Bundle(for:type(of: self)), compatibleWith: nil)!.cgImage!, UIImage(named: "gradient2.png", in: Bundle(for:type(of: self)), compatibleWith: nil)!.cgImage!, UIImage(named: "square.png", in: Bundle(for:type(of: self)), compatibleWith: nil)!.cgImage!] as [CGImage]
		lightRaysMaskImageContentsAnimation.keyTimes = [0.000, 0.600, 1.000] as [NSNumber]
		lightRaysMaskImageContentsAnimation.timingFunctions = [linearTiming, linearTiming]
		lightRaysMaskImageContentsAnimation.beginTime = beginTime
		lightRaysMaskImageContentsAnimation.fillMode = fillMode
		lightRaysMaskImageContentsAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Light Rays_mask"]?.layer.add(lightRaysMaskImageContentsAnimation, forKey:"showLightRays_ImageContents")

		let lightRaysMaskTranslationYAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
		lightRaysMaskTranslationYAnimation.duration = 0.250
		lightRaysMaskTranslationYAnimation.values = [0.000, 0.000, -40.000, -40.000] as [Float]
		lightRaysMaskTranslationYAnimation.keyTimes = [0.000, 0.200, 0.800, 1.000] as [NSNumber]
		lightRaysMaskTranslationYAnimation.timingFunctions = [linearTiming, linearTiming, linearTiming]
		lightRaysMaskTranslationYAnimation.beginTime = beginTime
		lightRaysMaskTranslationYAnimation.fillMode = fillMode
		lightRaysMaskTranslationYAnimation.isRemovedOnCompletion = removedOnCompletion
		self.viewsByName["Light Rays_mask__root"]?.layer.add(lightRaysMaskTranslationYAnimation, forKey:"showLightRays_TranslationY")
	}

	func removeShowLightRaysAnimation() {
		self.layer.removeAnimation(forKey: "ShowLightRays")
		self.viewsByName["Bulb__xScale"]?.layer.removeAnimation(forKey: "showLightRays_ScaleX")
		self.viewsByName["Bulb__yScale"]?.layer.removeAnimation(forKey: "showLightRays_ScaleY")
		self.viewsByName["Light Rays_mask"]?.layer.removeAnimation(forKey: "showLightRays_ImageContents")
		self.viewsByName["Light Rays_mask__root"]?.layer.removeAnimation(forKey: "showLightRays_TranslationY")
	}

	// MARK: CAAnimationDelegate
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		if let completion = self.animationCompletions[anim] {
			self.animationCompletions.removeValue(forKey: anim)
			completion(flag)
		}
	}

	func removeAllAnimations() {
		for subview in viewsByName.values {
			subview.layer.removeAllAnimations()
		}
		self.layer.removeAnimation(forKey: "RemoveLightRays")
		self.layer.removeAnimation(forKey: "ShowLightRays")
	}
}