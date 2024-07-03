import SwiftUI
import CodeScanner
import CoreData

struct ContentView: View {
    @State private var isPresentingScanner = false
    @State private var isPresentingNewCode = false
    @State private var scannedCode = "Unscanned"
    @State private var savedCode = ""
    @State private var savedCodeName = ""
    @State private var text = ""
    @Environment(\.colorScheme) var colorScheme
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
                                    Text("\(item.barcodeID ?? "N/A")")
                                        .font(.title)
                                    
                                    if let barcodeImage = generateBarcodeImage(from: item.barcodeID ?? "N/A") {
                                        barcodeImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 200, height: 100)
                                            .padding(.top)
                                        Text("\(item.barcodeID ?? "N/A")")
                                            .font(.footnote).tint(.gray)
                                    }
                                }
                            ) {
                                HStack {
                                    if let barcodeImage = generateBarcodeImage(from: String(item.barcodeID ?? "Null")) {
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
                    Label("Settings", systemImage: "gearshape")
                }
        }.accentColor(accentColor)
    }
    
    var newCode: some View {
        VStack {
            TextField("Enter barcode name", text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .padding()
            
            
            Button("scan", systemImage: "barcode.viewfinder") {
                isPresentingScanner = true
            }
            .sheet(isPresented: $isPresentingScanner) {
                scannerSheet
            }
            .font(.system(size: 28.0))
            .padding(.all)
            .tint(.blue)
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
            }.font(.system(size: 28.0)).padding(.all).tint(.blue).background(Color(.tertiaryLabel)).cornerRadius(12.0)
        }
    }

    
    var scannerSheet: some View {
        ZStack {
            CodeScannerView(
                codeTypes: [.code128],
                completion: { result in
                    if case let .success(code) = result {
                        scannedCode = code.string
                        savedCode = code.string
                        
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
    
    func generateBarcodeImage(from code: String) -> Image? {
        let barcode = BarcodeGenerator.generateBarcode(from: "\(code)")
        return Image(uiImage: barcode)
    }
}

struct BarcodeGenerator {
    static func generateBarcode(from string: String) -> UIImage {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            if let output = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 3, y: 3)
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
