//
//  ToolBar+NativeAPI.swift
//  animation
//
//  Created on 11/25/25.
// Show Native iOS26.1 Toolbar API in Note/Mail app

import SwiftUI

@available(iOS 26.0, *)
struct ToolBarSearchBarBottomAlignDemoView: View {
    @State private var searchText: String = ""
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {} label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Native API")
                            .fontWeight(.semibold)
                        Text("Toolbar morphing")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationSubtitle("6 Notes")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }
}

@available(iOS 26.0, *)
struct NoteStyleToolBarNativeAPIDemoView: View {
    @State private var searchText: String = ""
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    NoteStyleDetailedView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Native API")
                            .fontWeight(.semibold)
                        Text("Bounce Animation morphing")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationSubtitle("6 Notes")
            .toolbar {
                /// default tool bar place search bar to the bottom
                DefaultToolbarItem(kind: .search, placement: .bottomBar)

                /// split above and below tool bar items
                ToolbarSpacer(placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }
}

@available(iOS 26.0, *)
struct NoteStyleDetailedView: View {
    var body: some View {
        VStack {}
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 12) {
                        Button {} label: {
                            Image(systemName: "checklist")
                                .padding(.horizontal, 5)
                        }

                        Button {} label: {
                            Image(systemName: "paperclip")
                                .padding(.horizontal, 5)
                        }

                        Button {} label: {
                            Image(systemName: "pencil.tip.crop.circle")
                                .padding(.horizontal, 5)
                        }

                        Button {} label: {
                            Image(systemName: "apple.writing.tools")
                                .padding(.horizontal, 5)
                        }
                    }
                    .padding(.horizontal)
                    .buttonStyle(.plain)
                }
                /// split above and below tool bar items
                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
    }
}

@available(iOS 26.0, *)
#Preview {
    NoteStyleToolBarNativeAPIDemoView()
}

@available(iOS 26.0, *)
#Preview {
    MailStyleToolBarNativeAPIDemoView()
}

@available(iOS 26.0, *)
#Preview {
    ToolBarSearchBarBottomAlignDemoView()
}

@available(iOS 26.0, *)
struct MailStyleToolBarNativeAPIDemoView: View {
    @State private var searchText: String = ""
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    MailStyleDetailedView()
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.fill)
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Apple")
                                .fontWeight(.semibold)
                            Text("No bounce animation morphing")
                                .font(.caption)
                        }
                    }
                }
                /// use id to avoid animation bounce (personal preference) (
                .toolbar(id: "WRITEACTION") {
                    ToolbarItem(id: "WRITE", placement: .bottomBar) {
                        Button {} label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button {} label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                    }

                    /// split above and below tool bar items
                    ToolbarSpacer(.fixed, placement: .bottomBar)

                    /// default tool bar place search bar to the bottom
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)

                    /// split above and below tool bar items
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                }
                .searchable(text: $searchText)
            }
            .navigationTitle("Inbox")
            .navigationSubtitle("iCloud - Updated Just Now")
        }
    }
}

@available(iOS 26.0, *)
struct MailStyleDetailedView: View {
    var body: some View {
        VStack {}
            /// use id to avoid animation bounce (personal preference) (
            .toolbar(id: "WRITEACTION") {
                ToolbarItem(id: "WRITE", placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 12) {
                        Button {} label: {
                            Image(systemName: "trash")
                                .padding(.horizontal, 5)
                        }

                        Button {} label: {
                            Image(systemName: "folder")
                                .padding(.horizontal, 5)
                        }

                        Button {} label: {
                            Image(systemName: "arrowshape.turn.up.forward.fill")
                                .padding(.horizontal, 5)
                        }
                    }
                    .padding(.horizontal)
                    .buttonStyle(.plain)
                }
                /// split above and below tool bar items
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
    }
}
