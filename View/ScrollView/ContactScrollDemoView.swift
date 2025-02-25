//
//  ContactScrollDemoView.swift
//  animation
//
import SwiftUI

struct ContactSection: Identifiable {
    var id: String
    var contacts: [Contact]
    
    static func generateData() -> [ContactSection] {
        Dictionary(grouping: dummyContacts) {
            String($0.name.first ?? "A")
        }.compactMap {
            .init(id: $0.key, contacts: $0.value)
        }.sorted { $0.id < $1.id}
    }
}

struct ContactScrollDemoView: View {
    var body: some View {
        ContactScrollView()
    }
}

struct ContactScrollView: View {
    @State private var sections: [ContactSection] = ContactSection.generateData()
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 12) {
                ForEach(sections) { section in
                    SectionView(section)
                }
            }
            .padding(20)
        }
        .navigationTitle("Contacts")
    }
    
    func SectionView(_ section: ContactSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.id)
                .font(.largeTitle.bold())
            
            VStack(alignment: .leading, spacing: 15) {
                ForEach(section.contacts) { contact in
                    Text(contact.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    /// Skip divider for the last item
                    if contact.id != section.contacts.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}


#Preview {
    ContactScrollDemoView()
}
