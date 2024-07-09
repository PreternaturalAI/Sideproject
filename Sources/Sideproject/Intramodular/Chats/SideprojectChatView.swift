//
// Copyright (c) Vatsal Manot
//

import ChatKit
import LargeLanguageModels
import Swallow

public struct SideprojectChatView: View {
    @Environment(\.userInterfaceIdiom) var userInterfaceIdiom
    
    @StateObject var playground: Sideproject.ChatSession
    
    @State private var inputFieldText: String = ""
    
    @UserStorage("chat.inspectorVisibility")
    private var isInspectorPresented: Bool = false
    
    public var body: some View {
        ChatView {
            messagesList
            
            if playground.document.messages.isEmpty {
                ContentUnavailableView("No Messages", image: "message.fill")
            }
        } input: {
            ChatInputBar(
                text: $inputFieldText
            ) { message in
                playground.sendMessage(message)
            }
            .disabled(playground.activityPhaseOfLastItem == .sending)
        }
        .onChatInterrupt {
            playground.interrupt()
        }
        .activityPhaseOfLastItem(playground.activityPhaseOfLastItem)
        .frame(minWidth: 512)
        .toolbar {
            ToolbarItemGroup {
                Spacer()
                
                EditableText(
                    "Untitled thread",
                    text: $playground.document.metadata.displayName
                )
                
                Spacer()
                
                inspectorToggle
            }
        }
    }
    
    private var messagesList: some View {
        ChatMessageList(
            playground.document.messages
        ) { (message: Sideproject.ChatFile.Message) in
            ChatItemCell(item: message)
                .roleInvert(playground.ephemeralOptions.rolesReversed)
                .onEdit { (newValue: String) in
                    guard !newValue.isEmpty, (try? newValue == String(message.content)) == false else {
                        return
                    }
                    
                    let modifiedMessage: Sideproject.ChatFile.Message = withMutableScope(message) {
                        $0.content = PromptLiteral(newValue)
                    }
                    
                    playground.sendMessage(modifiedMessage)
                }
                .onDelete {
                    playground.delete(message.id)
                }
                .onResend {
                    playground.sendMessage(message)
                }
                .cocoaListItem(id: message.id)
                .chatItemDecoration(placement: .besideItem) {
                    Menu {
                        ChatItemActions()
                    } label: {
                        Image(systemName: .squareAndPencil)
                            .foregroundColor(.secondary)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                }
        }
    }
    
    private var inspectorToggle: some View {
        Button {
            isInspectorPresented.toggle()
        } label: {
            Image(systemName: .sidebarRight)
        }
    }
}
