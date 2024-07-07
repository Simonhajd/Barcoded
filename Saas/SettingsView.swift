import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: Text("Data & Preferences")) {
                        Label("Data & Preferences", systemImage: "gear")
                    }
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                Section(header: Text("Resources")) {
                    NavigationLink(destination: Text("User Guides")) {
                        Label("User Guides", systemImage: "book")
                    }
                    NavigationLink(destination: Text("FAQs")) {
                        Label("FAQs", systemImage: "questionmark.circle")
                    }
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: Text("Baggage Information")) {
                        Label("Baggage Information", systemImage: "bag")
                    }
                }
                Section {
                    NavigationLink(destination: Text("Suggest a Change ")) {
                        Label("Suggest a Change", systemImage: "envelope")
                    }
                    ShareLink(item: URL(string: "https://developer.apple.com/xcode/swiftui/")!) {
                        Label("Share the App", systemImage: "square.and.arrow.up")
                    }
                    ShareLink(item: URL(string: "https://developer.apple.com/xcode/swiftui/")!) {
                        Label("Rate the App", systemImage: "star")
                    }
                    
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle()) // Use InsetGroupedListStyle for rounded corners
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
