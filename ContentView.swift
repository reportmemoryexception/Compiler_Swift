/**
  ContentView.swift
  Compiler

  Created by Ben Chen on 2/4/24.
*/

import SwiftUI

struct RoundedRectangleButtonStyle:ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    // Get current environment color scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.top,2).padding(.bottom,3).padding(.leading,7).padding(.trailing,7)
            // Adjust the boarders
            .background(RoundedRectangle(cornerRadius:10).fill(colorScheme == .dark ? Color(red:0.25,green:0.25,blue:0.25):Color(red:0.875,green:0.875,blue:0.875)))
            // Different look for different color schemes
            .scaleEffect(configuration.isPressed ? 0.95:1.0)
            // Shrink while pressed
    }
}

struct debuggerSuggestionView:View {
    @Environment(\.presentationMode) var presentationMode
    // Is view presented
    @Binding var debuggerSuggestion:String
    // Text that displays
    var body: some View {
        ZStack {
            TextEditor(text: .constant(debuggerSuggestion)).font(.custom("Menlo",size:12))
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("close"){
                        if let window = NSApplication.shared.keyWindow {
                            presentationMode.wrappedValue.dismiss()
                            // Dismiss sheet view
                            window.close()
                        }
                    } .buttonStyle(RoundedRectangleButtonStyle())
                }
            } .padding(.trailing,8).padding(.bottom,8)
        }
    }
}

struct ContentView:View {
    
    @Environment(\.colorScheme) var colorScheme
    // Get environment color scheme
    @State private var compilerOutput:String = String()
    @State private var debug:String = String()
    @State private var alert:String = String()
    @State private var input:String = String()
    @State private var output:String = String()
    @State private var framework:String = String()
    @State private var isFrameworkCompile:Bool = false
    @State public var isDebuggerSuggestionVisible:Bool = false
    @State public var debuggerSuggestionValue:String = String()
    
    func compilerAction() -> Bool {
        var result:String = String()
        if !input.isEmpty && !output.isEmpty {
            if isFrameworkCompile {
                framework = String(framework.filter{$0 != Character("\\")})
                // Remove escape marks
                if framework.contains(", ") {
                    // Dilimiter
                    let frameworkArray:[String.SubSequence] = framework.split(separator:", ")
                    var args:[String] = []
                    for i:String.SubSequence in frameworkArray {
                        if !i.isEmpty {
                            args.append("-framework")
                            args.append(String(i))
                        }
                    }
                    args.append(input)
                    args.append("-o")
                    args.append(output)
                    // Arguments
                    result = compile(input,output,true,nil,true,args)
                } else {
                    result = compile(input,output,true,framework,false,[])
                }
            } else {
                result = compile(input,output,false,nil,false,[])
            }
            input = String()
            isFrameworkCompile = false
            framework = String()
            if checkError(result) {
                alert = result
                showAlert("Compiler Threw Error",result)
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
    
    
    
    var body:some View {
        let accent = Color(red:0.775,green:0.775,blue:0.775)
        let backgroundColor = (colorScheme == .dark) ? Color.black:Color.white
        VStack {
            VStack {
                HStack {
                    Text("Source Code: ")
                    ZStack {
                        TextField("Input File",text: $input)
                            .font(.custom("Menlo",size: 12))
                            .padding(.leading,7)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height:28)
                            .background(RoundedRectangle(cornerRadius:6).fill(backgroundColor).stroke(accent))
                            .padding(.leading,3)
                        HStack {
                            Spacer()
                            Button("choose...") {
                                input = chooseFile("Choose Input File...",false)
                            }
                            .buttonStyle(RoundedRectangleButtonStyle())
                            .padding(.trailing,4)
                        }
                    }
                }
                HStack {
                    Text("Output File: ")
                    ZStack {
                        TextField("Compiled Executable",text: $output)
                            .font(.custom("Menlo",size:12))
                            .padding(.leading,7)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height:28)
                            .background(RoundedRectangle(cornerRadius:6).fill(backgroundColor).stroke(accent))
                            .padding(.leading,14)
                        HStack {
                            Spacer()
                            Button("choose...") {
                                output = chooseFile("Choose Output Directory...",true)
                            }
                            .buttonStyle(RoundedRectangleButtonStyle())
                            .padding(.trailing,4)
                        }
                    }
                }
                Divider()
                HStack {
                    Toggle(isOn:$isFrameworkCompile) {
                        Text("use framework: ")
                    }
                    TextField(isFrameworkCompile ? "framework1, framework2...":"Framework Disabled...",text:$framework)
                        .font(.custom("Menlo",size:12))
                        .padding(.leading,5)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height:22)
                        .background(RoundedRectangle(cornerRadius:6).fill(backgroundColor).stroke(isFrameworkCompile ? accent:backgroundColor))
                        .disabled(!isFrameworkCompile)
                    Button("Compile") {
                        _ = compilerAction()
                        output = ""
                    } .keyboardShortcut("b",modifiers:.command)
                    // Command + B -> Build executable from source code file
                }
                Divider()
                HStack {
                    Text("Compiler: ")
                    Text(compilerOutput)
                    Text(alert)
                        .foregroundStyle(Color(red:1,green:0,blue:0))
                        .font(.custom("Menlo",size:12))
                    Spacer()
                    Button("Run & Debug") {
                        if compilerAction() {
                            let debugProcess:Process = Process()
                            debugProcess.launchPath = output
                            let pipe:Pipe = Pipe()
                            debugProcess.standardOutput = pipe
                            debugProcess.standardError = pipe
                            debugProcess.launch()
                            let data:Data = pipe.fileHandleForReading.readDataToEndOfFile()
                            let debuggerOutput:String = String(data:data,encoding:.utf8) ?? "(null)"
                            debug = debuggerOutput
                        } else {
                            debug = "Error: Failed Compiling"
                        }
                        output = ""
                    } .keyboardShortcut("r",modifiers:.command)
                    // Command + R -> Run and debug the compiled executable
                }
                HStack {
                    Text("Debug: ")
                    Spacer()
                    Button(action: {
                        compilerOutput = ""
                        debug = ""
                        alert = ""
                    }) {
                        Image(systemName:"trash").padding(.top, 1.50125)
                    } .frame(width:24).clipShape(Circle()).keyboardShortcut("k",modifiers:.command)
                    // Command + K -> Clear debug result and alert message
                }
            } .padding(.leading,8).padding(.trailing,8).padding(.top,8)
            ZStack {
                TextEditor(text:.constant(debug)).font(.custom("Menlo",size:12))
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Analyze"){
                            debuggerSuggestionValue = analyzeDebuggerOutput(debug)
                            isDebuggerSuggestionVisible = true
                        }
                        .buttonStyle(RoundedRectangleButtonStyle())
                    }
                } .padding(.trailing,8).padding(.bottom,8)
            }
            .sheet(isPresented:$isDebuggerSuggestionVisible,onDismiss: {
                isDebuggerSuggestionVisible = false
            }, content: {
                debuggerSuggestionView(debuggerSuggestion:$debuggerSuggestionValue).accentColor(Color(red:0,green:0,blue:0)).frame(minWidth:500,idealWidth:500,minHeight:300,idealHeight:300)
            })
        }
        
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews:some View {
        ContentView().accentColor(Color.black).frame(minWidth:450,idealWidth:450,maxWidth:.infinity,minHeight:450,idealHeight:450,maxHeight:.infinity)
    }
}

struct debuggerSuggestionView_Previews:PreviewProvider {
    static var previews:some View {
        @State var debuggerSuggestion = "Analyze got nothing..."
        debuggerSuggestionView(debuggerSuggestion:$debuggerSuggestion).accentColor(Color(red:0,green: 0,blue: 0))
            .frame(minWidth:500,idealWidth:500,minHeight:300,idealHeight:300)
        // Default view
    }
}
