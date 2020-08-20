//
//  Leila.swift
//  Leila
//
//  Created by Erick Almeida on 18/08/20.
//  Copyright © 2020 Erick Almeida. All rights reserved.
//

import Foundation

enum OptionType: String {
  case generate = "generate"
  case addFont = "add-font"
  case help = "help"
  case unknown
    
    init(value: String) {
        switch value {
          case "generate": self = .generate
          case "g": self = .generate
            
          case "add-font": self = .addFont
          case "af": self = .addFont

          case "help": self = .help
          case "--help": self = .help
            
          default: self = .unknown
        }
    }
}

class LeilaCLI {
    
    let taskRunner: LeilaTaskRunner
    let fileManager: FileManager
    
    public init() {
        self.fileManager = FileManager()
        self.taskRunner = LeilaTaskRunner(fileManager: self.fileManager, projectLocation: nil)
        
        if (CommandLine.argc >= 2) {
            let option = OptionType(value: CommandLine.arguments[1])
            
            switch option {
            case .generate:
                if (CommandLine.argc >= 4) {
                    taskRunner.generateImageSet(assetName: CommandLine.arguments[2], assetPath: CommandLine.arguments[3])
                } else {
                    taskRunner.showMissingArgumentError(forOption: OptionType.generate)
                }
            case .addFont:
                if (CommandLine.argc >= 3) {
                    taskRunner.addFont(fontPath: CommandLine.arguments[2])
                } else {
                    taskRunner.showMissingArgumentError(forOption: OptionType.addFont)
                }
            case .help:
                taskRunner.showHelp()
            case .unknown:
                taskRunner.showNoSuchCommandError()
            }
        } else {
            taskRunner.showHelp()
        }
        
        
    }
}
