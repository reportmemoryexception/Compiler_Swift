/**
  ContentView.swift
  Compiler_Swfit_Test

  Created by Ben Chen on 2/4/24.
*/

import SwiftUI

struct RoundedRectangleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.top, 2)
            .padding(.bottom, 3)
            .padding(.leading, 7)
            .padding(.trailing, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(red: 0.25, green: 0.25, blue: 0.25) : Color(red: 0.9, green: 0.9, blue: 0.9))
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}

struct debuggerSuggestionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var debuggerSuggestion: String
    var body: some View {
        ZStack {
            TextEditor(text: .constant(debuggerSuggestion)).font(.custom("Menlo", size: 12))
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("close"){
                        if let window = NSApplication.shared.keyWindow {
                            presentationMode.wrappedValue.dismiss()
                            window.close()
                        }
                    }
                    .buttonStyle(RoundedRectangleButtonStyle())
                }
            }
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
    }
}

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var compilerOutput: String = String()
    @State private var debug: String = String()
    @State private var alert: String = String()
    @State private var input: String = String()
    @State private var output: String = String()
    @State private var framework: String = String()
    @State private var isFrameworkCompile: Bool = false
    @State public var isDebuggerSuggestionVisible: Bool = false
    @State public var debuggerSuggestionValue: String = String()
    
    func compilerAction() -> Bool {
        var result: String = String()
        if !input.isEmpty && !output.isEmpty {
            if isFrameworkCompile {
                framework = String(framework.filter { $0 != Character("\\") })
                if framework.contains(", ") {
                    let frameworkArray: [String.SubSequence] = framework.split(separator: ", ")
                    var args: [String] = []
                    for i: String.SubSequence in frameworkArray {
                        if !i.isEmpty {
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
        return false
    }
    
    func chooseFile(title: String, isDir: Bool) -> String {
        let dialog = NSOpenPanel();
        dialog.title = title;
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = true;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = isDir;
        if dialog.runModal() ==  NSApplication.ModalResponse.OK {
            if (dialog.url != nil) {
                return String(dialog.url!.path)
            } else {
                return String()
            }
        } else {
            return String()
        }
    }
    
    var body: some View {
        let accent = Color(red:0.775, green: 0.775, blue: 0.775)
        let backgroundColor = (colorScheme == .dark) ? Color.black : Color.white
        VStack {
            VStack {
                HStack {
                    Text("Source Code:   ")
                    ZStack {
                        TextField("Input File", text: $input)
                            .font(.custom("Menlo", size: 12))
                            .padding(.leading, 7)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height: 28)
                            .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor).stroke(accent))
                        HStack {
                            Spacer()
                            Button("choose...") {
                                input = chooseFile(title: "Choose Input File...", isDir: false)
                            }
                            .buttonStyle(RoundedRectangleButtonStyle())
                            .padding(.trailing, 4)
                        }
                    }
                }
                HStack {
                    Text("Output File:   ")
                    ZStack {
                        TextField("Compiled Executable", text: $output)
                            .font(.custom("Menlo", size: 12))
                            .padding(.leading, 7)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height: 28)
                            .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor).stroke(accent))
                            .padding(.leading, 11)
                        HStack {
                            Spacer()
                            Button("choose...") {
                                output = chooseFile(title: "Choose Output Directory...", isDir: true)
                            }
                            .buttonStyle(RoundedRectangleButtonStyle())
                            .padding(.trailing, 4)
                        }
                    }
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
                            let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
                            let debuggerOutput: String = String(data: data, encoding: .utf8) ?? "(null)"
                            debug = debuggerOutput
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
            ZStack {
                TextEditor(text: .constant(debug)).font(.custom("Menlo", size: 12))
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Analyze"){
                            debuggerSuggestionValue = analyzeDebuggerOutput(debuggerOutput: debug)
                            isDebuggerSuggestionVisible = true
                        }
                        .buttonStyle(RoundedRectangleButtonStyle())
                    }
                }
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
            .sheet(isPresented: $isDebuggerSuggestionVisible, onDismiss: {
                isDebuggerSuggestionVisible = false
            }, content: {
                debuggerSuggestionView(debuggerSuggestion: $debuggerSuggestionValue).accentColor(Color.black).frame(minWidth: 500, idealWidth: 500, minHeight: 300, idealHeight: 300)
            })
        }
        
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().accentColor(Color.black).frame(minWidth: 450, idealWidth: 450, maxWidth: .infinity, minHeight: 450, idealHeight: 450, maxHeight: .infinity)
    }
}

struct debuggerSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        @State var debuggerSuggestion = "Analyze got nothing..."
        debuggerSuggestionView(debuggerSuggestion: $debuggerSuggestion).accentColor(Color.black).frame(minWidth: 500, idealWidth: 500, minHeight: 300, idealHeight: 300)
    }
}
