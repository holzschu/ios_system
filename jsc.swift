//
//  jsc.swift
//  ios_system
//
//  Created by Nicolas Holzschuch on 01/04/2020.
//  Copyright © 2020 Nicolas Holzschuch. All rights reserved.
//

import Foundation
import ios_system
import JavaScriptCore

func convertCArguments(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> [String]? {
    
    var args = [String]()
    
    for i in 0..<Int(argc) {
        
        guard let argC = argv?[i] else {
            return nil
        }
        
        let arg = String(cString: argC)
        
        args.append(arg)
        
    }
    
    return args
}

// execute JavaScript:
@_cdecl("jsc")
public func jsc(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    guard let args = convertCArguments(argc: argc, argv: argv) else { return 0 }
    let command = args[1]
    let fileName = FileManager().currentDirectoryPath + "/" + command
    do {
        let javascript = try String(contentsOf: URL(fileURLWithPath: fileName), encoding: String.Encoding.utf8)
        let context = JSContext()!
        context.exceptionHandler = { context, exception in
            fputs("jsc: " + exception!.toString() + "\n", thread_stderr)
        }
        if let result = context.evaluateScript(javascript) {
            if (!result.isUndefined) {
                let string = result.toString()
                fputs(string, thread_stdout)
                fputs("\n", thread_stdout)
                fflush(thread_stdout)
                fflush(thread_stderr)
            }
        }
    }
    catch {
        fputs("Error executing JavaScript  file: " + command + ": \(error) \n", thread_stderr)
        fflush(thread_stderr)
    }
    return 0
}
