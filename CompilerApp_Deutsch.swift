/**
  CompilerApp.swift
  Compiler

  Created by Ben Chen on 2/4/24.
*/

import SwiftUI

func showAlert(_ Title:String,_ Message:String) {
    let alert: NSAlert = NSAlert()
    alert.messageText = Title
    alert.informativeText = Message
    alert.addButton(withTitle:"ontslaan")
    alert.runModal()
}

func checkError(_ string:String) -> Bool {
    if string.contains("Error")||string.contains("error")||string.contains("FATAL")||string.contains("errno") {
        return true
    } else {
        return false
    }
}

func compile(_ input:String,_ output:String,_ isFramework:Bool,_ frameworkIdentifier:String?,_ isExternalArguments:Bool,_ externalArguments:[String]) -> String {
    var result:String = ""
    let fs = FileManager.default
    if fs.fileExists(atPath:input) {
        if !fs.fileExists(atPath:output) {
            let outputParent =  URL(fileURLWithPath:output).deletingLastPathComponent().path
            if !fs.fileExists(atPath:outputParent) {
                do {
                    try FileManager.default.createDirectory(atPath:outputParent,withIntermediateDirectories:true,attributes:nil)
                } catch {
                    let dirError = error.localizedDescription
                    result = "Onbekende fout: Fout bij het maken van een map: \"\(dirError)\""
                    return result
                }
            }
            let Extension:String = String(URL(fileURLWithPath:input).pathExtension)
            let task:Process = Process()
            var isFileSupport:Bool = true
            switch Extension {
            case "m":
                task.launchPath = "/usr/bin/clang"
                if isFramework {
                    if !isExternalArguments {
                        if !(frameworkIdentifier ?? String()).isEmpty {
                            task.arguments = [input,"-framework",(frameworkIdentifier ?? String()),"-o",output]
                        } else {
                            task.arguments = [input,"-o",output]
                        }
                    } else {
                        task.arguments = externalArguments
                    }
                } else {
                    task.arguments = [input,"-o",output]
                }
                break
            case "c":
                task.launchPath = "/usr/bin/gcc"
                task.arguments = [input,"-o",output]
                break
            case "cpp":
                task.launchPath = "/usr/bin/g++"
                task.arguments = [input,"-o",output]
                break
            default:
                result = "Fout: Ongeldig documenttype: \"\(Extension)\""
                isFileSupport = false
                break
            }
            if isFileSupport {
                let pipe:Pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                task.launch()
                task.waitUntilExit()
                let data:Data = pipe.fileHandleForReading.readDataToEndOfFile()
                result = String(data:data,encoding:.utf8) ?? "(null)"
            }
        } else {
            result = "Fout: Bestand bestaat al: \"\(output)\""
        }
    } else {
        result = "Fout: Niet zo'n bestand: \"\(input)\""
    }
    return result
}

func analyzeDebuggerOutput(_ debuggerOutput:String) -> String {
    if debuggerOutput == "Fout: Compileren mislukt" {
        // Compiler Action func returned false
        return "Compiler fout... Kan niet analyseren..."
    }
    let filteredPermissionErrorArray: [String] = debuggerOutput.components(separatedBy: "\n").filter {$0.contains("Operation not permitted")}
    // Get permission errors from debugger output
    var debugSuggestion:String = "Analyseren heeft niets..."
    if filteredPermissionErrorArray.count != 0 {
        debugSuggestion = "Waarschijnlijke toestemmingsfouten:\n"
        for i:String in filteredPermissionErrorArray {
            debugSuggestion.append("\(i)\n")
        }
    }
    return debugSuggestion
}

func chooseFile(_ title:String,_ isDir:Bool) -> String {
    let dialog = NSOpenPanel();
    dialog.title = title;
    dialog.showsResizeIndicator = true;
    dialog.showsHiddenFiles = true;
    dialog.allowsMultipleSelection = false;
    dialog.canChooseDirectories = isDir;
    if dialog.runModal() == NSApplication.ModalResponse.OK {
        if dialog.url != nil {
            return String(dialog.url!.path)
        } else {
            return ""
        }
    } else {
        return ""
    }
}

@main

struct Compiler_Swfit_TestApp:App {
    var body:some Scene {
        WindowGroup {
            ContentView().accentColor(Color(red:0,green:0,blue:0)).frame(minWidth:450,idealWidth:450,maxWidth:.infinity,minHeight:450,idealHeight:450,maxHeight:.infinity)
        }
    }
}
