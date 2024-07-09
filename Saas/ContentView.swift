import SwiftUI
import CodeScanner
import CoreData
import AVFoundation

enum BarcodeType {
    case code128
    case qrCode
    case pdf417
    case aztec
    case ean13
    case ean8
    
    var filterName: String {
        switch self {
        case .code128:
            return "CICode128BarcodeGenerator"
        case .qrCode:
            return "CIQRCodeGenerator"
        case .pdf417:
            return "CIPDF417BarcodeGenerator"
        case .aztec:
            return "CIAztecCodeGenerator"
        case .ean13:
            return "CIEAN13BarcodeGenerator"
        case .ean8:
            return "CIEAN8BarcodeGenerator"
        }
    }
}

struct ContentView: View {
    @State private var isPresentingScanner = false
    @State private var isPresentingNewCode = false
    @State private var scannedCode = "Unscanned"
    @State private var savedCode = ""
    @State private var savedCodeName = ""
    @State private var CodeType = ""
    @State private var text = ""
    @Environment(\.colorScheme) var colorScheme
    @State private var isFullScreen: Bool = false
    @State private var rotationAngle: Double = 0
    var accentColor: Color {
            colorScheme == .dark ? Color.white : Color.black
        }

    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.barcodeID, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        TabView {
            NavigationView {
                VStack(spacing: -10) {
                    List {
                        ForEach(items) { item in
                            NavigationLink(
                                destination: VStack {
                                    
                                    if !isFullScreen {
                                        Text("\(item.barcodeName ?? "N/A")")
                                            .font(.title)
                                    }
                                        
                                    if let barcodeImage = generateBarcodeImage(from: item.barcodeID ?? "N/A", type: .code128) {
                                        VStack {
                                            barcodeImage
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .scaleEffect(x: isFullScreen ? 1.5 : 0.75, y: isFullScreen ? 1.5 : 0.75)
                                                .padding(.top)
                                                .rotationEffect(.degrees(rotationAngle))
                                                .onTapGesture {
                                                    withAnimation(.easeInOut(duration: 0.5)) {
                                                        isFullScreen.toggle()
                                                        rotationAngle += 90
                                                    }
                                                }
                                        }
                                        
                                        if !isFullScreen {
                                            Text("\(item.barcodeID ?? "N/A")")
                                                .font(.footnote).tint(.gray)
                                        }
                                    }
                                }
                            ) {
                                HStack {
                                    if let barcodeImage = generateBarcodeImage(from: String(item.barcodeID ?? "Null"), type: .code128) {
                                        barcodeImage
                                            .resizable()
                                            .frame(width: 100, height: 50) // Adjust the size as needed
                                            .padding(.trailing, 10)
                                        
                                    }
                                    VStack(alignment: .leading) {
                                        Text("\(item.barcodeName ?? "N/A")") // Assuming barcodeName is an optional String
                                            .font(.headline)
                                        Text("Barcode ID: \(item.barcodeID ?? "N/A")")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem {
                            Button {
                                isPresentingScanner = false
                                isPresentingNewCode = true // Add this state variable
                            } label: {
                                Image(systemName: "plus")
                            }
                            .sheet(isPresented: $isPresentingNewCode) { // Update the sheet to open newCode
                                newCode
                            }
                        }
                    }
                }
            }
            .tabItem {
                Label("Barcodes", systemImage: "barcode.viewfinder")
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                    //Label("Settings", systemImage: "gearshape")
                }
        }.accentColor(accentColor)
    }
    
    var newCode: some View {
        VStack() {
            TextField("Enter barcode name", text: $text)
                .textFieldStyle(.automatic)
                .multilineTextAlignment(.center)
                .padding()
                
            Button("Scan", systemImage: "barcode.viewfinder") {
                isPresentingScanner = true
            }
            .sheet(isPresented: $isPresentingScanner) {
                scannerSheet
            }
            .font(.system(size: 28.0))
            .padding(.all)
            .tint(Color("AccentColor"))
            .background(savedCode.isEmpty ? Color(.tertiaryLabel) : Color.green)
            .cornerRadius(12.0)
            Button("Save", systemImage: "square.and.arrow.down.fill") {
                if !text.isEmpty {
                    savedCodeName = text
                } else {
                    savedCodeName = "" // Default value or handle the error case as needed
                }

                let newItem = Item(context: viewContext)
                newItem.barcodeName = text
                newItem.barcodeID = (savedCode)

                do {
                    try viewContext.save()
                    text = ""
                    savedCode = ""
                } catch {
                    print("Error saving to Core Data: \(error)")
                    // Handle the error as needed
                }

                isPresentingNewCode = false
            }.font(.system(size: 28.0)).padding(.all).tint(Color("AccentColor")).background(Color(.tertiaryLabel)).cornerRadius(12.0)
        }
    }

    
    var scannerSheet: some View {
        ZStack {
            CodeScannerView(
                codeTypes: [.code128, .qr, .ean8, .ean13, .pdf417, .aztec],
                showViewfinder: true,
                simulatedData: "Paul Hudson",
                
                // Add more types as needed
                completion: { result in
                    if case let .success(code) = result {
                        scannedCode = code.string
                        savedCode = code.string
                        CodeType = code.string
                        isPresentingScanner = false
                    }
                }
            )
            .ignoresSafeArea(.all)
            
            Rectangle()
                .stroke(Color.blue, lineWidth: 4)
                .frame(width: 120, height: 90)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func generateBarcodeImage(from code: String, type: BarcodeType) -> Image? {
        let barcode = BarcodeGenerator.generateBarcode(from: code, type: type)
        return Image(uiImage: barcode)
    }
}

struct BarcodeGenerator {
    static func generateBarcode(from string: String, type: BarcodeType) -> UIImage {
        let data = string.data(using: .ascii)
        
        if let filter = CIFilter(name: type.filterName) {
            filter.setValue(data, forKey: "inputMessage")
            
            if type == .qrCode {
                filter.setValue("M", forKey: "inputCorrectionLevel")
            }
            
            if let output = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledOutput = output.transformed(by: transform)
                if let cgImage = CIContext().createCGImage(scaledOutput, from: scaledOutput.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return UIImage(systemName: "xmark.circle")!
    }
}

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
