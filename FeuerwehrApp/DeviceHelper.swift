//
//  DeviceHelper.swift
//  FeuerwehrApp
//
//  Created by Yannick Luginbühl on 16.05.25.
//


import UIKit

// Neue Hilfsklasse statt Extension
struct DeviceHelper {
    static var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
