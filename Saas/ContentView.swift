import SwiftUI
import CodeScanner
import CoreData
import AVFoundation

enum BarcodeType: String {
    case code128 = "org.iso.Code128"
    case qrCode = "org.iso.QRCode"
    case pdf417 = "org.iso.PDF417"
    case aztec = "org.iso.Aztec"
    case ean13 = "org.gs1.EAN-13"
    case ean8 = "org.iso.EAN8"
    
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
            return "CIEAN13BarcodeGenerator" //ciean13barcodegenerator may not be real or may be under a different name
        case .ean8:
            return "CIEAN8BarcodeGenerator"
        }
    }
    
    init?(from string: String) {
        switch string {
        case "org.iso.Code128":
            self = .code128
        case "org.iso.QRCode":
            self = .qrCode
        case "org.iso.PDF417":
            self = .pdf417
        case "org.iso.Aztec":
            self = .aztec
        case "org.gs1.EAN-13":
            self = .ean13
        case "org.iso.EAN8":
            self = .ean8
        default:
            return nil
        }
    }
} 

struct ContentView: View {
    @State private var isPresentingScanner = false
    @State private var isPresentingNewCode = false
    @State private var scannedCode = "Unscanned"
    @State private var savedCode = ""
    @State private var savedCodeName = ""
    @State private var codeType = ""
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
                                        Text("\(item.barcodeType ?? "N/A")")
                                            .font(.title)

                                    }
                                    
                                        
                                    if let barcodeType = BarcodeType(from: item.barcodeType ?? ""),
                                        let barcodeImage = generateBarcodeImage(from: item.barcodeID ?? "N/A", type: barcodeType) {
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
                                    if let barcodeType = BarcodeType(from: item.barcodeType ?? ""),
                                       let barcodeImage = generateBarcodeImage(from: String(item.barcodeID ?? "Null"), type: barcodeType) {
                                        barcodeImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 50) // Adjust the size as needed
                                            .padding(.trailing, 10)
                                            .layoutPriority(1) // Ensure the image retains its size
                                    }
                                    VStack(alignment: .leading) {
                                        Text("\(item.barcodeName ?? "N/A")") // Assuming barcodeName is an optional String
                                            .font(.headline)
                                            .layoutPriority(2) // Give higher priority to the text
                                        Text("Barcode ID: \(item.barcodeID ?? "N/A")")
                                            .font(.subheadline)
                                            .layoutPriority(2) // Give higher priority to the text
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
                newItem.barcodeType = (codeType)

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
                showViewfinder: false,
                simulatedData: "Paul Hudson",
                
                // Add more types as needed
                completion: { result in
                    if case let .success(code) = result {
                        scannedCode = code.string
                        savedCode = code.string
                        codeType = code.type.rawValue
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
