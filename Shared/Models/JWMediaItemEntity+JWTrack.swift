//
//  JWMediaItemEntity+JWTrack.swift
//  EasyPlayer
//
//  Created by 王杰 on 2018/9/20.
//  Copyright © 2018年 Jerry Wong. All rights reserved.
//

import Foundation

extension JWMediaItemEntity {
    
    @objc func toTrack() -> JWTrack {
        let track = JWTrack()
        track.name = name
        track.artist = artist
        track.album = album
        track.location = location
        track.totalTime = totalTime?.doubleValue ?? 0
        track.sourceType = .local
        track.id = objectID
        return track
    }
    
    @objc func sync(withTrack track: JWTrack) {
        name = track.name
        artist = track.artist
        album = track.album
        location = track.location
        totalTime = track.totalTime as NSNumber
        track.id = objectID
    }
    
}
