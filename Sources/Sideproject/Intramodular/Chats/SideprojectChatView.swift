//
// Copyright (c) Vatsal Manot
//

import ChatKit
import LargeLanguageModels
import Swallow

public struct SideprojectChatView: View {
    @Environment(\.userInterfaceIdiom) var userInterfaceIdiom
    
    @StateObject var session: Sideproject.ChatSession
    
    @State private var inputFieldText: String = ""
    
    @UserStorage("chat.inspectorVisibility")
    private var isInspectorPresented: Bool = false
    
    public init(session: @autoclosure @escaping () -> Sideproject.ChatSession) {
        self._session = .init(wrappedValue: session())
    }

    public init(
        _ data: @autoclosure @escaping () throws -> Sideproject.ChatFile,
        llm: LLMRequestHandling = Sideproject.shared
    ) {
        self.init(
            session: Sideproject.ChatSession(
                document: try PublishedAsyncBinding<Sideproject.ChatFile>(wrappedValue: data()),
                llm: llm
            )
        )
    }
    
    public init<T: AbstractLLM.ChatMessageConvertible>(
        messages: some Sequence<T>,
        llm: LLMRequestHandling = Sideproject.shared
    ) {
        self.init(try Sideproject.ChatFile(messages: messages), llm: llm)
    }

    public var body: some View {
        ChatView {
            messagesList
            
            if session.document.messages.isEmpty {
                ContentUnavailableView("No Messages", image: "message.fill")
            }
        } input: {
            ChatInputBar(
                text: $inputFieldText
            ) { message in
                session.sendMessage(message)
            }
            .disabled(session.activityPhaseOfLastItem == .sending)
        }
        .onChatInterrupt {
            session.interrupt()
        }
        .activityPhaseOfLastItem(session.activityPhaseOfLastItem)
        .frame(minWidth: 512)
        .toolbar {
            ToolbarItemGroup {
                Spacer()
                
                EditableText(
                    "Untitled thread",
                    text: $session.document.metadata.displayName
                )
                
                Spacer()
                
                inspectorToggle
            }
        }
    }
    
    private var messagesList: some View {
        ChatMessageList(
            session.document.messages
        ) { (message: Sideproject.ChatFile.Message) in
            ChatItemCell(item: message)
                .roleInvert(session.ephemeralOptions.rolesReversed)
                .onEdit { (newValue: String) in
                    guard !newValue.isEmpty, (try? newValue == String(message.content)) == false else {
                        return
                    }
                    
                    let modifiedMessage: Sideproject.ChatFile.Message = withMutableScope(message) {
                        $0.content = PromptLiteral(newValue)
                    }
                    
                    session.sendMessage(modifiedMessage)
                }
                .onDelete {
                    session.delete(message.id)
                }
                .onResend {
                    session.sendMessage(message)
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
        .onEdit { (message, content) in
            session.document.messages[id: message]?.content = PromptLiteral(content)
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
