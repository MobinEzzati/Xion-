//
//  ContentView.swift
//  Xion
//
//  Created by Mobin  Ezzati  on 3/14/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ChatView()
                .navigationTitle("AI Chat")
        }
    }
}

#Preview {
    ContentView()
}
