//
//  JWMediaItemEntity+CoreDataProperties.swift
//  EasyPlayer
//
//  Created by 王杰 on 2018/9/20.
//  Copyright © 2018年 Jerry Wong. All rights reserved.
//
//

import Foundation
import CoreData

extension JWMediaItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWMediaItemEntity> {
        return NSFetchRequest<JWMediaItemEntity>(entityName: "JWMediaItemEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var artist: String?
    @NSManaged public var album: String?
    @NSManaged public var location: String?
    @NSManaged public var totalTime: NSNumber?

}
