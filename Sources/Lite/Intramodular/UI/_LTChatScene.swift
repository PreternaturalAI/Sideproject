//
// Copyright (c) Vatsal Manot
//

import ChatKit
import LargeLanguageModels
import Swallow

struct ChatSceneContent: DynamicView {
    @Environment(\.userInterfaceIdiom) var userInterfaceIdiom
    
    @StateObject var playground: LTChatPlayground
    
    @State private var inputFieldText: String = ""
    
    @UserStorage("chat.inspectorVisibility")
    private var isInspectorPresented: Bool = false
    
    var body: some View {
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
        ) { message in
            ChatItemCell(item: message)
                .roleInvert(playground.ephemeralOptions.rolesReversed)
                .onEdit { (newValue: String) in
                    guard !newValue.isEmpty, (try? newValue == message.base._stripToText()) == false else {
                        return
                    }
                    
                    playground.sendMessage(withMutableScope(message) {
                        $0.base.content = PromptLiteral(newValue)
                    })
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


extension AbstractLLM.ChatRole: ChatKit.ChatItemRoleConvertible {
    public func __conversion() -> any ChatItemRole {
        switch self {
            case .system:
                return ChatItemRoles.SenderRecipient.sender // FIXME: !!!
            case .user:
                return ChatItemRoles.SenderRecipient.sender
            case .assistant:
                return ChatItemRoles.SenderRecipient.recipient
            case .other:
                fatalError()
        }
    }
}

extension AbstractLLM.ChatMessage: ChatKit.ChatMessageConvertible {
    public func __conversion() -> AnyChatMessage {
        AnyChatMessage(
            id: self.id,
            role: self.role.__conversion(),
            body: self.content.debugDescription
        )
    }
}
