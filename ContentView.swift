/**
  ContentView.swift
  Compiler_Swfit_Test

  Created by Ben Chen on 2/4/24.
*/

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var compilerOutput: String = String()
    @State private var debug: String = String()
    @State private var alert: String = String()
    @State private var input: String = String()
    @State private var output: String = String()
    @State private var framework: String = String()
    @State private var isFrameworkCompile: Bool = false
    
    func compilerAction() -> Bool {
        var result: String = String()
        if !input.isEmpty && !output.isEmpty {
            if isFrameworkCompile {
                if framework.contains(", ") {
                    let frameworkArray: Array = framework.split(separator: ", ")
                    var args: [String] = []
                    for i: String.SubSequence in frameworkArray {
                        while !i.isEmpty {
                            args.append("-framework")
                            args.append(String(i))
                        }
                    }
                    args.append(input)
                    args.append("-o")
                    args.append(output)
                    result = compile(input: input, output: output, isFramework: true, frameworkIdentifier: String(), isExternalArguments: true, externalArguments: args)
                } else {
                    result = compile(input: input, output: output, isFramework: true, frameworkIdentifier: framework, isExternalArguments: false, externalArguments: [])
                }
            } else {
                result = compile(input: input, output: output, isFramework: false, frameworkIdentifier: String(), isExternalArguments: false, externalArguments: [])
            }
            input = String()
            isFrameworkCompile = false
            framework = String()
            if checkError(string: result) {
                alert = result
                showAlert(Title: "Compiler Threw Error", Message: result)
                result.removeAll()
                return false
            } else {
                compilerOutput = result
                result.removeAll()
                return true
            }
        }
        return true
    }
    
    var body: some View {
        let accent = Color(red:0.775, green: 0.775, blue: 0.775)
        let backgroundColor = (colorScheme == .dark) ? Color.black : Color.white
        VStack {
            VStack {
                HStack {
                    Text("Source Code: ")
                    TextField("Input File", text: $input)
                        .font(.custom("Menlo", size: 12))
                        .padding(.leading, 5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor).stroke(accent))
                }
                HStack {
                    Text("Output File: ")
                    TextField("Compiled Executable", text: $output)
                        .font(.custom("Menlo", size: 12))
                        .padding(.leading, 5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor).stroke(accent))
                        .padding(.leading, 11)
                }
                Divider()
                HStack {
                    Toggle(isOn: $isFrameworkCompile) {
                        Text("with framework: ")
                    }
                    TextField(isFrameworkCompile ? "framework1, framework2..." : "Framework Disabled...", text: $framework)
                        .font(.custom("Menlo", size: 12))
                        .padding(.leading, 5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor).stroke(isFrameworkCompile ? accent : backgroundColor))
                        .disabled(!isFrameworkCompile)
                    Button("Compile") {
                        _ = compilerAction()
                        output = String()
                    } .keyboardShortcut("b", modifiers: .command)
                    // Command + B -> Build executable from source code file
                }
                Divider()
                HStack {
                    Text("Compiler: ")
                    Text(compilerOutput)
                    Text(alert)
                        .foregroundStyle(Color(red: 1, green: 0, blue: 0))
                        .font(.custom("Menlo", size: 12))
                    Spacer()
                    Button("Run & Debug") {
                        if compilerAction() {
                            let debugProcess: Process = Process()
                            debugProcess.launchPath = output
                            let pipe: Pipe = Pipe()
                            debugProcess.standardOutput = pipe
                            debugProcess.standardError = pipe
                            debugProcess.launch()
                            debugProcess.waitUntilExit()
                            let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
                            debug = String(data: data, encoding: .utf8) ?? "(null)"
                        } else {
                            debug = "Error: Failed Compiling"
                        }
                        output = String()
                    } .keyboardShortcut("r", modifiers: .command)
                    // Command + R -> Run and debug the compiled executable
                }
                HStack {
                    Text("Debug: ")
                    Spacer()
                    Button(action: {
                        compilerOutput = String()
                        debug = String()
                        alert = String()
                    }) {
                        Image(systemName: "trash")
                    } .frame(width: 24).clipShape(Circle()).keyboardShortcut("k", modifiers: .command)
                    // Command + K
                }
            }
                .padding(.leading, 8).padding(.trailing, 8).padding(.top, 8)
            TextEditor(text: .constant(debug))
                .font(.custom("Menlo", size: 12))
        }
        
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().accentColor(Color.black).frame(minWidth: 450, idealWidth: 450, maxWidth: .infinity, minHeight: 450, idealHeight: 450, maxHeight: .infinity)
    }
}
