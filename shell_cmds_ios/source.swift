//
//  source.swift
//  shell
//
//  Created by Nicolas Holzschuch on 16/01/2022.
//  Copyright © 2022 Nicolas Holzschuch. All rights reserved.
//

import Foundation
import ios_system


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

// TODO: create commands makeGlobal, makeLocal in libc_replacement

// Small replacement for the "source" shell command.
// Everything that affects the current shell should affect the current shell (for now: setenv and cd).
// Files with "if" / "while" commands are going to fail.
@_cdecl("source")
public func source(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let shortUsage = "usage: source file [file2] [file3]\n"
    guard let args = convertCArguments(argc: argc, argv: argv) else {
        fputs(shortUsage, thread_stdout)
        return 0
    }
    if args.count == 1 {
        fputs(shortUsage, thread_stdout)
        return 0
    }
    // To make environment global, set environment[current_pid] to null, restore afterwards
    makeGlobal()  // setenv commands go global
    for i in 1..<args.count {
        let fileName = URL(fileURLWithPath: args[i])
        // A bit specific for Python virtual environments, because we don't know where the file is at creation.
        let virtualEnvDir = fileName.deletingLastPathComponent().deletingLastPathComponent().path
        setenv("__VENV_DIR__", virtualEnvDir, 1)
        //
        if (FileManager().fileExists(atPath: fileName.path)) {
            do {
                let contentOfFile = try String(contentsOf: fileName, encoding: String.Encoding.utf8)
                let commands = contentOfFile.split(separator: "\n")
                for command in commands {
                    let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
                    if (trimmedCommand.count == 0) { continue } // skip white lines
                    if (trimmedCommand.hasPrefix("#")) { continue } // skip comments
                    // reset the LC_CTYPE (some commands (luatex) can change it):
                    setenv("LC_CTYPE", "UTF-8", 1);
                    setlocale(LC_CTYPE, "UTF-8");
                    // Todo: make cd globzl: ???
                    let pid = ios_fork()
                    _ = ios_system(trimmedCommand)
                    fflush(thread_stdout)
                    ios_waitpid(pid)
                    ios_releaseThreadId(pid)
                }
            }
            catch {
                fputs("source: error loading \(fileName).", thread_stderr)
            }
        } else {
            fputs("source: file \(fileName) not found.", thread_stderr)
        }
    }
    unsetenv("__VENV_DIR__")
    makeLocal() // back to local
    newPreviousDirectory() // make directory changes permanent
    return 0
}

// Now check that it *does* change the environment when run. Should not. Might have to be edited.
// HOW? detect "setenv" and "cd"?
