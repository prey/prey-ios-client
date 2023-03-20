//
//  Alarm.swift
//  Prey
//
//  Created by Javier Cala Uribe on 16/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class Alarm : PreyAction, AVAudioPlayerDelegate {
 
    // MARK: Properties
    var audioPlayer: AVAudioPlayer!
    var checkVolumeTimer: Timer?
    
    // MARK: Functions
    // Prey command
    override func start() {
        PreyLogger("Playing alarm now")
        
        do {
            // Config AVAudioSession on device
            let audioSession = AVAudioSession.sharedInstance()
            audioSession.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with:[AVAudioSession.CategoryOptions.mixWithOthers])
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            
            // Config Volume System
            UIApplication.shared.beginReceivingRemoteControlEvents()
            let volumeView = MPVolumeView()
            volumeView.volumeSlider.setValue(1.0, animated: false)

            // Check Volume level
            checkVolumeTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(incrementVolume(_:)), userInfo: nil, repeats: true)
            
            // Play sound
            guard let pathFile = Bundle.main.path(forResource: "siren", ofType: "mp3") else {
                stopAction()
                return
            }
            let musicFile   = URL(fileURLWithPath: pathFile)
            try audioPlayer = AVAudioPlayer(contentsOf: musicFile)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0
            audioPlayer.numberOfLoops = 1
            audioPlayer.play()
            
            // Send start action
            isActive = true
            let params = getParamsTo(kAction.alarm.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
            self.sendData(params, toEndpoint: responseDeviceEndpoint)
            let paramName:[String: Any] = [ "name" : UIDevice.current.name]
            self.sendData(paramName, toEndpoint: dataDeviceEndpoint)
            PreyDevice.infoDevice({(isSuccess: Bool) in
                PreyLogger("infoDevice isSuccess: \(isSuccess)")
            })
            
        } catch let error as NSError {
            PreyLogger("AVAudioSession error: \(error.localizedDescription)")
            stopAction()
        }
    }
    
    // Check Volume Level
    @objc func incrementVolume(_ timer:Timer)  {

        let volumeView = MPVolumeView()
        if volumeView.volumeSlider.value < 1.0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                volumeView.volumeSlider.setValue(1.0, animated: false)
            }
        }
    }
    
    // Stop Action
    func stopAction() {
        isActive = false
        checkVolumeTimer?.invalidate()
        let params = getParamsTo(kAction.alarm.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
    }
    
    // MARK: AVAudioPlayerDelegate

    // Did Finish Playing
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Send stop action
        stopAction()
    }
    
    // Player Decode Error Did Occur
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // Send stop action
        stopAction()
    }
}
