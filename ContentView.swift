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
                    // Delimiter found
                    let frameworkArray: Array = framework.split(separator: ", ")
                    // Split framework input by delimiter and store in array
                    var args: [String] = []
                    // Create array to store processed components
                    for i: String.SubSequence in frameworkArray {
                        args.append("-framework")
                        args.append(String(i))
                    }
                    // Now the array contains argument without input and output
                    args.append(input)
                    args.append("-o")
                    args.append(output)
                    // Add input and output to array
                    // Array Becomes full argument
                    result = compile(input: input, output: output, isFramework: true, frameworkIdentifier: String(), isExternalArguments: true, externalArguments: args)
                    // Run compiler with externalArgument: processed array
                } else {
                    result = compile(input: input, output: output, isFramework: true, frameworkIdentifier: framework, isExternalArguments: false, externalArguments: [])
                    // No delimiter
                }
            } else {
                result = compile(input: input, output: output, isFramework: false, frameworkIdentifier: String(), isExternalArguments: false, externalArguments: [])
                // No framework
            }
            input = String()
            isFrameworkCompile = false
            framework = String()
            if (checkError(string: result)) {
                alert = result
                showAlert(Title: "Compiler Threw Error", Message: result)
                result.removeAll()
                return true
                // Successfully compiled
            } else {
                compilerOutput = result
                result.removeAll()
                return false
                // Failed compiling
            }
        }
        return true
    }
    
    var body: some View {
        let accentGray = Color(red:0.775, green: 0.775, blue: 0.775)
        VStack {
            VStack {
                HStack {
                    Text("Source Code: ")
                    TextField("Input File", text: $input)
                        .font(.custom("Menlo", size: 12))
                        .padding(.leading, 5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(colorScheme == .dark ? Color.black : Color.white).stroke(accentGray))
                }
                HStack {
                    Text("Output File: ")
                    TextField("Compiled Executable", text: $output)
                        .font(.custom("Menlo", size: 12))
                        .padding(.leading, 5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(colorScheme == .dark ? Color.black : Color.white).stroke(accentGray))
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
                        .background(RoundedRectangle(cornerRadius: 6).fill(colorScheme == .dark ? Color.black : Color.white).stroke(isFrameworkCompile ? accentGray : colorScheme == .dark ? Color.black : Color.white))
                        .disabled(!isFrameworkCompile)
                    Button("Compile") {
                        _ = compilerAction()
                        // Run compiler action
                        output = String()
                    } .keyboardShortcut("b", modifiers: .command)
                    // Command + B
                }
                Divider()
                HStack {
                    Text("Compiler: ")
                    Text(compilerOutput)
                    Text(alert)
                        .foregroundStyle(Color.red)
                        .font(.custom("Menlo", size: 12))
                    Spacer()
                    Button("Run & Debug") {
                        if compilerAction() {
                            // Compile Succeeded
                            let debugProcess: Process = Process()
                            debugProcess.launchPath = output
                            // Set launch path to compiled executable
                            let pipe = Pipe()
                            debugProcess.standardOutput = pipe
                            debugProcess.standardError = pipe
                            // Get Stdout and Stderr into pipe
                            debugProcess.launch()
                            debugProcess.waitUntilExit()
                            // Launch and wait for exit
                            let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
                            debug = String(data: data, encoding: .utf8) ?? String()
                            // Read data from pipe and output it to TextView
                        } else {
                            // Failed compiling
                            debug = "Error: Failed Compiling"
                        }
                        output = String()
                    } .keyboardShortcut("r", modifiers: .command)
                    // Command + R
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
        ContentView()
    }
}
