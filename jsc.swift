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

extension URL {
    // shorthand to check if URL is directory
    public var isDirectory: Bool {
        let keys = Set<URLResourceKey>([URLResourceKey.isDirectoryKey])
        let value = try? self.resourceValues(forKeys: keys)
        switch value?.isDirectory {
        case .some(true):
            return true
            
        default:
            return false
        }
    }
}

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

func printUsage() {
    fputs("Usage: jsc file.js\n", thread_stdout)
}

// TODO:
// add searching for modules in ~/Library
// npm to install new modules (not parcel, though)

// execute JavaScript:
@_cdecl("jsc")
public func jsc(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    if (argc != 2) {
        printUsage()
        return 0
    }
    guard let args = convertCArguments(argc: argc, argv: argv) else {
        printUsage()
        return 0
    }
    let command = args[1]
    let fileName = FileManager().currentDirectoryPath + "/" + command
    do {
        let javascript = try String(contentsOf: URL(fileURLWithPath: fileName), encoding: String.Encoding.utf8)
        let context = JSContext()!
        
        context.exceptionHandler = { context, exception in
            let line = exception!.objectForKeyedSubscript("line").toString()
            let column = exception!.objectForKeyedSubscript("column").toString()
            let stacktrace = exception!.objectForKeyedSubscript("stack").toString()
            let unknown = "<unknown>"
            fputs("jsc: Error ", thread_stderr)
            if let currentFilename = context?.evaluateScript("if (typeof __filename !== 'undefined') { __filename }") {
                if (!currentFilename.isUndefined) {
                    let file = currentFilename.toString()
                    fputs("in file " + (file ?? unknown) + " ", thread_stderr)
                }
            }
            fputs("at line " + (line ?? unknown), thread_stderr)
            fputs(", column: " + (column ?? unknown) + ": ", thread_stderr)
            fputs(exception!.toString() + "\n", thread_stderr)
            if (stacktrace != nil) {
                fputs("jsc: Full stack: " + stacktrace! + "\n", thread_stderr)
            }
        }
        let print: @convention(block) (String) -> Void = { string in
            fputs(string, thread_stdout)
        }
        context.setObject(print, forKeyedSubscript: "print" as NSString)
        let println: @convention(block) (String) -> Void = { string in
            fputs(string + "\n", thread_stdout)
        }
        context.setObject(println, forKeyedSubscript: "println" as NSString)
        // console.log
        context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        let consoleLog: @convention(block) (String) -> Void = { message in
            fputs("console.log: " + message + "\n", thread_stderr)
        }
        context.setObject(consoleLog, forKeyedSubscript: "_consoleLog" as NSString)
        // exports, __filename, and __dirname
        // require
        let require: @convention(block) (String) -> (JSValue?) = { path in
            // Store module, filename, exports, dirname before if they exist. Restore them at the end.
            let currentDirectory = context.evaluateScript("if (typeof __dirname !== 'undefined') { __dirname }")
            let currentFilename = context.evaluateScript("if (typeof __filename !== 'undefined') { __filename }")
            let currentExports = context.evaluateScript("if (typeof exports !== 'undefined') { exports }")
            let currentModule = context.evaluateScript("if (typeof module !== 'undefined') { module }")
            var expandedPath = NSString(string: path).expandingTildeInPath
            if (expandedPath.hasPrefix(".")) {
                if (currentDirectory != nil) {
                    if (!currentDirectory!.isUndefined) {
                        NSLog("currentDirectory = \(currentDirectory!)")
                        var shortPath = expandedPath
                        shortPath.removeFirst(".".count)
                        expandedPath = currentDirectory!.toString() + shortPath
                    }
                }
            }
            let expandedPathFile = expandedPath + ".js"
            if (!FileManager.default.fileExists(atPath: expandedPath) && !FileManager.default.fileExists(atPath: expandedPathFile)) {
                // Not found locally, trying globally
                let bundleUrl = URL(fileURLWithPath: Bundle.main.resourcePath!)
                let newUrl = bundleUrl.appendingPathComponent("node_modules").appendingPathComponent(path)
                if (FileManager.default.fileExists(atPath: newUrl.path)) {
                    expandedPath = newUrl.path
                    if (newUrl.isDirectory) {
                        let browserUrl = newUrl.appendingPathComponent("browser.js")
                        if (FileManager.default.fileExists(atPath: browserUrl.path)) {
                            expandedPath = browserUrl.path
                        } else {
                            let indexUrl = newUrl.appendingPathComponent("index.js")
                            if (FileManager.default.fileExists(atPath: indexUrl.path)) {
                                expandedPath = indexUrl.path
                            }
                        }
                    }
                }
            }
            if (!FileManager.default.fileExists(atPath: expandedPath) && FileManager.default.fileExists(atPath: expandedPathFile)) {
                expandedPath = expandedPathFile
            }
            // Return void or throw an error here.
            guard FileManager.default.fileExists(atPath: expandedPath)
                else {
                    fputs("Require: filename \(expandedPath) not found.\n", thread_stderr)
                    return nil
            }
            guard let fileContent = try? String(contentsOfFile: expandedPath)
                else {
                    fputs("Empty content for: \(expandedPath)\n", thread_stderr)
                    return nil
            }
            // module and exports. One for each module we load with require:
            let dirName = URL(fileURLWithPath: expandedPath).deletingLastPathComponent().path
            context.evaluateScript("var module = { id: '.', exports: {}, parent: null, filename: '" + expandedPath + "',  dirname: '" + dirName + "', loaded: false, children: [], paths: []};")
            context.evaluateScript("var exports = module.exports; var __filename = module.filename; var __dirname = module.dirname; ")
            let returnValue = context.evaluateScript(fileContent)
            // Restore previous value for module, exports, etc:
            if (currentModule != nil) {
                if (!currentModule!.isUndefined) {
                    context.setObject(currentModule, forKeyedSubscript: "module" as NSString)
                    context.evaluateScript("exports = module.exports; __filename = module.filename; __dirname = module.dirname; ")
                }
            }
            // send return
            return returnValue
        }
        context.setObject(require, forKeyedSubscript: "require" as NSString)
        // actual script execution:
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
