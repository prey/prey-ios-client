//
//  Alarm.swift
//  Prey
//
//  Created by Javier Cala Uribe on 16/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class Alarm : PreyAction, AVAudioPlayerDelegate {
 
    // MARK: Properties

    var audioPlayer: AVAudioPlayer!
    
    // MARK: Functions

    // Prey command
    override func start() {
        print("Playing alarm now")
        
        do {
            // Config AVAudioSession on device
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
            
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()

            // Play sound
            let musicFile   = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("siren", ofType: "mp3")!)
            try audioPlayer = AVAudioPlayer(contentsOfURL: musicFile)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0            
            audioPlayer.play()
            
            // Send start action
            isActive = true
            let params = getParamsTo(kAction.ALARM.rawValue, command: kCommand.START.rawValue, status: kStatus.STARTED.rawValue)
            self.sendData(params, toEndpoint: responseDeviceEndpoint)
            
        } catch let error as NSError {
            print("AVAudioSession error: \(error.localizedDescription)")
        }
    }
    
    // MARK: AVAudioPlayerDelegate

    // Did Finish Playing
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        // Send stop action
        isActive = false
        let params = getParamsTo(kAction.ALARM.rawValue, command: kCommand.STOP.rawValue, status: kStatus.STOPPED.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
    }
    
    // Player Decode Error Did Occur
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        // Send stop action
        isActive = false
        let params = getParamsTo(kAction.ALARM.rawValue, command: kCommand.STOP.rawValue, status: kStatus.STOPPED.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
    }
}