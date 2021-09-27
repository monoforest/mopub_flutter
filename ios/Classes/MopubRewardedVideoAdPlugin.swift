//
//  MopubRewardedVideoAdPlugin.swift
//  mopub_flutter
//
//  Created by Rohit Kulkarni on 1/7/20.
//

import Foundation
import MoPubSDK

public class MopubRewardedVideoAdPlugin: NSObject, FlutterPlugin {
    
    fileprivate var pluginRegistrar: FlutterPluginRegistrar?
//    Need to keep strong reference to delegate because MoPub by default keeps weak reference
    fileprivate var delegate: MPRewardedAdsDelegate?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MopubRewardedVideoAdPlugin()
        instance.pluginRegistrar = registrar
        let channel = FlutterMethodChannel(name: MopubConstants.REWARDED_VIDEO_CHANNEL, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String : Any] ?? [:]
        let adUnitId = args["adUnitId"] as? String ?? "ad_unit_id"
        
        switch call.method {
        case MopubConstants.SHOW_REWARDED_VIDEO_METHOD:
            if(MPRewardedAds.hasAdAvailable(forAdUnitID: adUnitId)) {
                let reward = MPRewardedAds.selectedReward(forAdUnitID: adUnitId)
                let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                MPRewardedAds.presentRewardedAd(forAdUnitID: adUnitId, from: rootViewController, with: reward)
            }
            result(nil)
            break;
        case MopubConstants.LOAD_REWARDED_VIDEO_METHOD:            
            let channelName = "\(MopubConstants.REWARDED_VIDEO_CHANNEL)_\(adUnitId)"
            let adChannel = FlutterMethodChannel(name: channelName, binaryMessenger: pluginRegistrar!.messenger())
            self.delegate = MopubRewardedVideoDelegate(channel: adChannel)
            
            MPRewardedAds.removeDelegate(forAdUnitId: adUnitId)
            MPRewardedAds.setDelegate(delegate, forAdUnitId: adUnitId)
            MPRewardedAds.loadRewardedAd(withAdUnitID: adUnitId, withMediationSettings: nil)
            result(nil)
            break
        case MopubConstants.HAS_REWARDED_VIDEO_METHOD:
            let hasAd = MPRewardedAds.hasAdAvailable(forAdUnitID: adUnitId)
            result(hasAd);
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

class MopubRewardedVideoDelegate: NSObject, MPRewardedAdsDelegate {
    let channel: FlutterMethodChannel
    var didReceiveReward: Bool
    var rewardAmount: NSNumber
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.didReceiveReward = false
        self.rewardAmount = 0
    }
    
    func rewardedAdDidLoad(forAdUnitID adUnitID: String!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        channel.invokeMethod(MopubConstants.LOADED_METHOD, arguments: args)
    }
    
    func rewardedAdDidFailToLoad(forAdUnitID adUnitID: String!, error: Error!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        args["errorCode"] = error.localizedDescription
        channel.invokeMethod(MopubConstants.ERROR_METHOD, arguments: args)
    }
    
    func rewardedAdWillPresent(forAdUnitID adUnitID: String!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        channel.invokeMethod(MopubConstants.DISPLAYED_METHOD, arguments: args)
    }

    
    func rewardedAdDidFailToShow(forAdUnitID adUnitID: String!, error: Error!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        args["errorCode"] = error.localizedDescription
        channel.invokeMethod(MopubConstants.REWARDED_PLAYBACK_ERROR, arguments: args)
    }
    
    
    func rewardedAdDidDismiss(forAdUnitID adUnitID: String!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        channel.invokeMethod(MopubConstants.DISMISSED_METHOD, arguments: args)
        if(didReceiveReward) {
            didReceiveReward = false
            var args:[String:Any] = [:]
            args["reward"] = rewardAmount
            channel.invokeMethod(MopubConstants.GRANT_REWARD, arguments: args)
        }
    }
    
    func rewardedAdDidReceiveTapEvent(forAdUnitID adUnitID: String!) {
        var args:[String:Any] = [:]
        args["adUnitId"] = adUnitID
        channel.invokeMethod(MopubConstants.CLICKED_METHOD, arguments: args)
    }
    
    func rewardedAdShouldReward(forAdUnitID adUnitID: String!, reward: MPReward!) {
        self.didReceiveReward = true
        self.rewardAmount = reward.amount
    }
    
        
    func rewardedAdDidExpire(forAdUnitID adUnitID: String!) {
        MPRewardedAds.loadRewardedAd(withAdUnitID: adUnitID, withMediationSettings: nil)
    }
}
