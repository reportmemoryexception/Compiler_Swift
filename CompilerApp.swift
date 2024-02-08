/**
  Compiler_Swfit_TestApp.swift
  Compiler_Swfit_Test

  Created by Ben Chen on 2/4/24.
*/

import SwiftUI

func showAlert(Title: String, Message: String) {
    let alert: NSAlert = NSAlert()
    alert.messageText = Title
    alert.informativeText = Message
    alert.addButton(withTitle: "dismiss")
    alert.runModal()
}

func checkError(string: String) -> Bool {
    if string.contains("Error")||string.contains("error")||string.contains("FATAL")||string.contains("errno") {
        return true
    } else {
        return false
    }
}

func compile(input: String, output: String, isFramework: Bool, frameworkIdentifier: String, isExternalArguments: Bool, externalArguments: [String]) -> String {
    var result = String()
    let fs = FileManager.default
    if fs.fileExists(atPath: input) {
        if !fs.fileExists(atPath: output) {
            let outputParent =  URL(fileURLWithPath: output).deletingLastPathComponent().path
            if !fs.fileExists(atPath: outputParent) {
                do {
                    try FileManager.default.createDirectory(atPath: outputParent, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    showAlert(Title: "Unknown Error", Message: "Error creating directory: \(error.localizedDescription)")
                }
            }
            let Extension: String = String(URL(fileURLWithPath: input).pathExtension)
            let task: Process = Process()
            var isFileSupport: Bool = true
            switch Extension {
            case "m":
                task.launchPath = "/usr/bin/clang"
                if isFramework {
                    if !isExternalArguments {
                        if !frameworkIdentifier.isEmpty {
                            task.arguments = [input, "-framework", frameworkIdentifier, "-o", output]
                        } else {
                            task.arguments = [input, "-o", output]
                        }
                    } else {
                        task.arguments = externalArguments
                    }
                } else {
                    task.arguments = [input, "-o", output]
                }
                break
            case "c":
                task.launchPath = "/usr/bin/gcc"
                task.arguments = [input, "-o", output]
                break
            case "cpp":
                task.launchPath = "/usr/bin/g++"
                task.arguments = [input, "-o", output]
                break
            default:
                result = "Error: Bad Document Type: \"\(Extension)\""
                isFileSupport = false
                break
            }
            if isFileSupport {
                let pipe: Pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                task.launch()
                task.waitUntilExit()
                let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
                result = String(data: data, encoding: .utf8) ?? "(null)"
            }
        } else {
            result = "Error: File Already Exists: \"\(output)\""
        }
    } else {
        result = "Error: No Such File: \"\(input)\""
    }
    return result
}

@main

struct Compiler_Swfit_TestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().accentColor(Color(red: 0, green: 0, blue: 0)).frame(minWidth: 450, idealWidth: 450, maxWidth: .infinity, minHeight: 450, idealHeight: 450, maxHeight: .infinity)
        }
    }
}
