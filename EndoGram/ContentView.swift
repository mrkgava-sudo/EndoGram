import SwiftUI

// MARK: - Local data models

struct EGMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var date: Date = Date()
    var isOutgoing: Bool
    var isRead: Bool = true
}

struct EGChat: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var username: String
    var avatar: String
    var color: String
    var kind: String
    var isPinned: Bool = false
    var isArchived: Bool = false
    var unread: Int = 0
    var isMuted: Bool = false
    var messages: [EGMessage] = []

    var lastMessage: EGMessage? { messages.last }
}

struct EGContact: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var username: String
    var avatar: String
    var color: String
}

// MARK: - Persistent offline store

@MainActor
final class LocalMessengerStore: ObservableObject {
    @Published private(set) var chats: [EGChat] = []
    @Published private(set) var contacts: [EGContact] = []
    @Published var displayName: String = "Мой профиль" { didSet { saveProfile() } }
    @Published var username: String = "endogram_user" { didSet { saveProfile() } }
    @Published var bio: String = "В EndoGram" { didSet { saveProfile() } }

    private let chatsKey = "endogram.local.chats.v2"
    private let contactsKey = "endogram.local.contacts.v2"
    private let profileKey = "endogram.local.profile.v2"

    init() {
        load()
        if chats.isEmpty && contacts.isEmpty { seedDemoData() }
    }

    var activeChats: [EGChat] { chats.filter { !$0.isArchived } }
    var archivedChats: [EGChat] { chats.filter { $0.isArchived } }

    func chat(_ id: UUID) -> EGChat? { chats.first { $0.id == id } }

    func send(_ text: String, to id: UUID) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let index = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[index].messages.append(EGMessage(text: value, isOutgoing: true))
        chats[index].unread = 0
        persist()
    }

    func createContact(name: String, username: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !cleanName.isEmpty else { return }
        let contact = EGContact(name: cleanName, username: cleanUsername, avatar: String(cleanName.prefix(1)).uppercased(), color: palette[contacts.count % palette.count])
        contacts.append(contact)
        persist()
    }

    @discardableResult
    func openChat(with contact: EGContact) -> UUID {
        if let existing = chats.first(where: { $0.username == contact.username && !$0.username.isEmpty }) { return existing.id }
        let newChat = EGChat(title: contact.name, username: contact.username, avatar: contact.avatar, color: contact.color, kind: "Личный", messages: [EGMessage(text: "Это начало вашей переписки в EndoGram.", isOutgoing: false)])
        chats.insert(newChat, at: 0)
        persist()
        return newChat.id
    }

    func createGroup(title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        chats.insert(EGChat(title: clean, username: "", avatar: "person.3.fill", color: palette[chats.count % palette.count], kind: "Группа"), at: 0)
        persist()
    }

    func togglePin(_ id: UUID) {
        guard let i = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[i].isPinned.toggle()
        chats.sort { $0.isPinned && !$1.isPinned }
        persist()
    }

    func toggleArchive(_ id: UUID) {
        guard let i = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[i].isArchived.toggle()
        persist()
    }

    func deleteChat(_ id: UUID) {
        chats.removeAll { $0.id == id }
        persist()
    }

    func clearUnread(_ id: UUID) {
        guard let i = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[i].unread = 0
        persist()
    }

    private let palette = ["blue", "purple", "pink", "orange", "green", "indigo", "teal"]

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: chatsKey), let value = try? decoder.decode([EGChat].self, from: data) { chats = value }
        if let data = UserDefaults.standard.data(forKey: contactsKey), let value = try? decoder.decode([EGContact].self, from: data) { contacts = value }
        if let data = UserDefaults.standard.data(forKey: profileKey), let value = try? decoder.decode([String].self, from: data), value.count == 3 {
            displayName = value[0]; username = value[1]; bio = value[2]
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(chats) { UserDefaults.standard.set(data, forKey: chatsKey) }
        if let data = try? encoder.encode(contacts) { UserDefaults.standard.set(data, forKey: contactsKey) }
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode([displayName, username, bio]) { UserDefaults.standard.set(data, forKey: profileKey) }
    }

    private func seedDemoData() {
        let people = [
            EGContact(name: "Александр", username: "alexander", avatar: "А", color: "orange"),
            EGContact(name: "Мария", username: "maria", avatar: "М", color: "purple"),
            EGContact(name: "Илья", username: "ilya", avatar: "И", color: "green"),
            EGContact(name: "Дизайн и идеи", username: "design", avatar: "paintpalette.fill", color: "pink"),
            EGContact(name: "Разработка", username: "devteam", avatar: "chevron.left.forwardslash.chevron.right", color: "indigo")
        ]
        contacts = people
        chats = [
            EGChat(title: "EndoGram", username: "endogram", avatar: "paperplane.fill", color: "blue", kind: "Личный", isPinned: true, messages: [EGMessage(text: "Добро пожаловать! Это ваш локальный мессенджер.", isOutgoing: false)]),
            EGChat(title: "Александр", username: "alexander", avatar: "А", color: "orange", kind: "Личный", isPinned: true, unread: 2, messages: [EGMessage(text: "Привет! Как дела?", isOutgoing: false), EGMessage(text: "Всё отлично 👍", isOutgoing: true), EGMessage(text: "Давай созвонимся позже", isOutgoing: false)]),
            EGChat(title: "Дизайн и идеи", username: "design", avatar: "paintpalette.fill", color: "pink", kind: "Группа", messages: [EGMessage(text: "Мария: отправила макет", isOutgoing: false)]),
            EGChat(title: "Илья", username: "ilya", avatar: "И", color: "green", kind: "Личный", messages: [EGMessage(text: "Спасибо!", isOutgoing: false)]),
            EGChat(title: "Разработка", username: "devteam", avatar: "chevron.left.forwardslash.chevron.right", color: "indigo", kind: "Группа", unread: 4, messages: [EGMessage(text: "Новый билд готов", isOutgoing: false)]),
            EGChat(title: "Мама", username: "mom", avatar: "М", color: "pink", kind: "Личный", messages: [EGMessage(text: "Не забудь написать ❤️", isOutgoing: false)])
        ]
        persist()
    }
}

// MARK: - Theme

private enum EGTheme {
    static let blue = Color(red: 0.10, green: 0.55, blue: 0.94)
    static let muted = Color(red: 0.48, green: 0.52, blue: 0.57)
    static let canvas = Color(red: 0.95, green: 0.96, blue: 0.97)
    static let line = Color(red: 0.89, green: 0.90, blue: 0.92)
    static func color(_ name: String) -> Color {
        switch name {
        case "purple": return .purple
        case "pink": return .pink
        case "orange": return .orange
        case "green": return .green
        case "indigo": return .indigo
        case "teal": return .teal
        default: return blue
        }
    }
}

// MARK: - App tabs

struct MainTabView: View {
    @StateObject private var store = LocalMessengerStore()
    var body: some View {
        TabView {
            ChatsView()
                .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill") }
            ContactsView()
                .tabItem { Label("Контакты", systemImage: "person.crop.circle") }
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(EGTheme.blue)
        .environmentObject(store)
    }
}

// MARK: - Chat list and folders

struct ChatsView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @State private var search = ""
    @State private var folder = "Все"
    @State private var showNewMessage = false
    @State private var showArchive = false

    private let folders = ["Все", "Личные", "Группы"]

    private var visibleChats: [EGChat] {
        store.activeChats.filter { chat in
            let matchesFolder = folder == "Все" || (folder == "Личные" && chat.kind == "Личный") || (folder == "Группы" && chat.kind == "Группа")
            let matchesSearch = search.isEmpty || chat.title.localizedCaseInsensitiveContains(search) || chat.username.localizedCaseInsensitiveContains(search) || (chat.lastMessage?.text.localizedCaseInsensitiveContains(search) ?? false)
            return matchesFolder && matchesSearch
        }.sorted { $0.isPinned && !$1.isPinned }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(folders, id: \.self) { item in
                            Button { folder = item } label: {
                                Text(item).font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(folder == item ? .white : EGTheme.muted)
                                    .padding(.horizontal, 16).padding(.vertical, 9)
                                    .background(folder == item ? EGTheme.blue : EGTheme.canvas, in: Capsule())
                            }
                        }
                        Button { showArchive = true } label: {
                            Image(systemName: "archivebox").foregroundStyle(EGTheme.muted)
                                .padding(10).background(EGTheme.canvas, in: Circle())
                        }
                    }.padding(.horizontal, 16).padding(.vertical, 10)
                }
                List {
                    ForEach(visibleChats) { chat in
                        NavigationLink {
                            ConversationView(chatID: chat.id)
                        } label: {
                            ChatRow(chat: chat)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { store.deleteChat(chat.id) } label: { Label("Удалить", systemImage: "trash") }
                            Button { store.toggleArchive(chat.id) } label: { Label("Архив", systemImage: "archivebox") }.tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button { store.togglePin(chat.id) } label: { Label(chat.isPinned ? "Открепить" : "Закрепить", systemImage: "pin") }.tint(EGTheme.blue)
                        }
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if visibleChats.isEmpty {
                        ContentUnavailableView("Чатов пока нет", systemImage: "bubble.left.and.bubble.right", description: Text("Создайте переписку через кнопку нового сообщения."))
                    }
                }
            }
            .navigationTitle("EndoGram")
            .searchable(text: $search, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {} label: { Image(systemName: "line.3.horizontal").font(.system(size: 18)) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewMessage = true } label: { Image(systemName: "square.and.pencil").font(.system(size: 19)) }
                }
            }
            .sheet(isPresented: $showNewMessage) { NewMessageView() }
            .navigationDestination(isPresented: $showArchive) { ArchiveView() }
        }
    }
}

private struct ChatRow: View {
    let chat: EGChat
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(value: chat.avatar, color: chat.color, size: 54)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(chat.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary)
                    Spacer()
                    if chat.isMuted { Image(systemName: "bell.slash.fill").font(.system(size: 10)).foregroundStyle(EGTheme.muted) }
                    Text(chat.lastMessage.map { $0.date.formatted(date: .omitted, time: .shortened) } ?? "")
                        .font(.system(size: 12)).foregroundStyle(EGTheme.muted)
                }
                HStack(spacing: 5) {
                    Text(chat.lastMessage?.text ?? "Нет сообщений")
                        .font(.system(size: 14)).foregroundStyle(EGTheme.muted).lineLimit(1)
                    Spacer(minLength: 4)
                    if chat.unread > 0 {
                        Text("\(chat.unread)").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3).background(EGTheme.blue, in: Capsule())
                    } else if chat.isPinned {
                        Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(EGTheme.muted)
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

struct ArchiveView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    var body: some View {
        List {
            ForEach(store.archivedChats) { chat in
                HStack {
                    ChatRow(chat: chat)
                    Spacer()
                    Button("Вернуть") { store.toggleArchive(chat.id) }.font(.system(size: 13))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Архив")
        .overlay {
            if store.archivedChats.isEmpty { ContentUnavailableView("Архив пуст", systemImage: "archivebox") }
        }
    }
}

// MARK: - Conversation

struct ConversationView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    let chatID: UUID
    @State private var draft = ""
    @State private var showAttachment = false
    @FocusState private var inputFocused: Bool

    private var chat: EGChat? { store.chat(chatID) }

    var body: some View {
        VStack(spacing: 0) {
            if let chat {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 9) {
                            Text("Сегодня").font(.system(size: 12, weight: .medium)).foregroundStyle(EGTheme.muted)
                                .padding(.horizontal, 12).padding(.vertical, 6).background(.white.opacity(0.85), in: Capsule()).padding(.vertical, 8)
                            ForEach(chat.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }.padding(12)
                    }
                    .background(Color(red: 0.91, green: 0.93, blue: 0.94))
                    .onChange(of: chat.messages.count) { _ in
                        if let last = chat.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                composer
            } else {
                ContentUnavailableView("Чат не найден", systemImage: "bubble.left")
            }
        }
        .navigationTitle(chat?.title ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(chat?.title ?? "Чат").font(.system(size: 16, weight: .semibold))
                    Text(chat?.kind == "Группа" ? "группа" : "был(а) недавно").font(.system(size: 11)).foregroundStyle(EGTheme.muted)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let chat { NavigationLink { ChatInfoView(chat: chat) } label: { AvatarView(value: chat.avatar, color: chat.color, size: 32) } }
            }
        }
        .onAppear { store.clearUnread(chatID) }
        .confirmationDialog("Вложение", isPresented: $showAttachment, titleVisibility: .visible) {
            Button("Фото или видео") {}
            Button("Файл") {}
            Button("Геопозиция") {}
            Button("Отмена", role: .cancel) {}
        } message: { Text("Вложения в офлайн-версии пока представлены демонстрационными пунктами.") }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 9) {
            Button { showAttachment = true } label: { Image(systemName: "paperclip").font(.system(size: 21)).foregroundStyle(EGTheme.blue).frame(width: 30, height: 38) }
            TextField("Сообщение", text: $draft, axis: .vertical)
                .lineLimit(1...5).focused($inputFocused)
                .padding(.horizontal, 14).padding(.vertical, 9).background(EGTheme.canvas, in: RoundedRectangle(cornerRadius: 19))
            Button(action: send) {
                Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(EGTheme.blue, in: Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(.horizontal, 10).padding(.vertical, 8).background(.white)
    }

    private func send() {
        store.send(draft, to: chatID)
        draft = ""
    }
}

private struct MessageBubble: View {
    let message: EGMessage
    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 48) }
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text).font(.system(size: 16)).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 3) {
                    Text(message.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 10)).foregroundStyle(EGTheme.muted)
                    if message.isOutgoing { Image(systemName: "checkmark").font(.system(size: 9, weight: .semibold)).foregroundStyle(EGTheme.blue) }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(message.isOutgoing ? Color(red: 0.83, green: 0.94, blue: 0.79) : .white, in: RoundedRectangle(cornerRadius: 15))
            if !message.isOutgoing { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Chat info

struct ChatInfoView: View {
    let chat: EGChat
    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    AvatarView(value: chat.avatar, color: chat.color, size: 92)
                    Text(chat.title).font(.system(size: 22, weight: .bold))
                    if !chat.username.isEmpty { Text("@\(chat.username)").foregroundStyle(EGTheme.muted) }
                    Text(chat.kind).font(.system(size: 13)).foregroundStyle(EGTheme.muted)
                }.frame(maxWidth: .infinity).padding(.vertical, 16)
            }
            Section("Действия") {
                Label("Уведомления", systemImage: "bell")
                Label("Поиск по переписке", systemImage: "magnifyingglass")
                Label("Общие медиа", systemImage: "photo.on.rectangle")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Информация")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contacts and new message

struct ContactsView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @State private var search = ""
    @State private var showAdd = false
    @State private var selectedChat: UUID?

    private var filtered: [EGContact] {
        store.contacts.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.username.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showAdd = true } label: { Label("Добавить контакт", systemImage: "person.badge.plus").foregroundStyle(EGTheme.blue) }
                }
                Section("Контакты") {
                    ForEach(filtered) { contact in
                        Button { selectedChat = store.openChat(with: contact) } label: {
                            HStack(spacing: 12) {
                                AvatarView(value: contact.avatar, color: contact.color, size: 46)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(contact.name).font(.system(size: 16, weight: .medium)).foregroundStyle(.primary)
                                    Text(contact.username.isEmpty ? "локальный контакт" : "@\(contact.username)").font(.system(size: 13)).foregroundStyle(EGTheme.muted)
                                }
                            }.padding(.vertical, 2)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Контакты")
            .searchable(text: $search, prompt: "Поиск контактов")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showAdd = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showAdd) { AddContactView() }
            .navigationDestination(item: $selectedChat) { id in ConversationView(chatID: id) }
        }
    }
}

struct NewMessageView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showAdd = true } label: { Label("Новый контакт", systemImage: "person.badge.plus") }
                    Button { store.createGroup(title: "Новая группа"); dismiss() } label: { Label("Новая группа", systemImage: "person.2") }
                }
                Section("Контакты") {
                    ForEach(store.contacts.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.username.localizedCaseInsensitiveContains(search) }) { contact in
                        Button { _ = store.openChat(with: contact); dismiss() } label: {
                            HStack(spacing: 12) {
                                AvatarView(value: contact.avatar, color: contact.color, size: 42)
                                VStack(alignment: .leading) {
                                    Text(contact.name).foregroundStyle(.primary)
                                    Text("@\(contact.username)").font(.system(size: 12)).foregroundStyle(EGTheme.muted)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новое сообщение")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Имя или username")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Отмена") { dismiss() } } }
            .sheet(isPresented: $showAdd) { AddContactView() }
        }
    }
}

struct AddContactView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var username = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Контакт") {
                    TextField("Имя", text: $name)
                    TextField("@username (необязательно)", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Section { Text("Контакт сохранится только на этом устройстве. Поиск реальных пользователей пока не подключён.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Новый контакт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { store.createContact(name: name, username: username); dismiss() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Profile and settings

struct SettingsView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @AppStorage("eg_demo_premium") private var premiumEnabled = false
    @State private var notifications = true
    @State private var sounds = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { ProfileView() } label: {
                        HStack(spacing: 13) {
                            AvatarView(value: String(store.displayName.prefix(1)), color: "blue", size: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.displayName).font(.system(size: 18, weight: .semibold))
                                Text("@\(store.username)").font(.system(size: 14)).foregroundStyle(EGTheme.muted)
                                Text("Изменить профиль").font(.system(size: 13)).foregroundStyle(EGTheme.blue)
                            }
                        }.padding(.vertical, 5)
                    }
                }
                Section {
                    NavigationLink { PremiumHubView() } label: { settingsRow("EndoGram Premium", icon: "star.circle.fill", color: .purple) }
                    NavigationLink { StarsHubView() } label: { settingsRow("Мои звёзды", icon: "star.fill", color: .orange) }
                    NavigationLink { GiftsHubView() } label: { settingsRow("Подарки", icon: "gift.fill", color: .pink) }
                }
                Section {
                    NavigationLink { SimpleSettingsPage(title: "Уведомления", subtitle: "Настройки уведомлений на устройстве") } label: { settingsRow("Уведомления", icon: "bell.badge", color: .red) }
                    NavigationLink { SimpleSettingsPage(title: "Конфиденциальность", subtitle: "Локальный прототип: параметры приватности пока не влияют на сетевое поведение.") } label: { settingsRow("Конфиденциальность", icon: "lock", color: .blue) }
                    NavigationLink { SimpleSettingsPage(title: "Данные и память", subtitle: "История чатов хранится локально в памяти приложения.") } label: { settingsRow("Данные и память", icon: "externaldrive", color: .green) }
                    NavigationLink { SimpleSettingsPage(title: "Оформление", subtitle: "Выбор тем будет добавлен отдельно.") } label: { settingsRow("Оформление", icon: "paintbrush", color: .purple) }
                }
                Section {
                    Toggle("Уведомления", isOn: $notifications)
                    Toggle("Звуки", isOn: $sounds)
                }
                Section {
                    NavigationLink { SimpleSettingsPage(title: "Помощь", subtitle: "EndoGram — самостоятельный офлайн-прототип.") } label: { settingsRow("Помощь", icon: "questionmark.circle", color: .gray) }
                    HStack { Text("Версия"); Spacer(); Text("0.2 · Offline").foregroundStyle(EGTheme.muted) }.font(.system(size: 13))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Настройки")
        }
    }

    private func settingsRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .medium)).foregroundStyle(.white)
                .frame(width: 30, height: 30).background(color.gradient, in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.system(size: 16))
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: LocalMessengerStore
    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""

    var body: some View {
        Form {
            Section {
                AvatarView(value: String((name.isEmpty ? store.displayName : name).prefix(1)), color: "blue", size: 86)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            Section("Данные") {
                TextField("Имя", text: $name)
                TextField("Username", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("О себе", text: $bio)
            }
            Section {
                Button("Сохранить изменения") {
                    store.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? store.displayName : name
                    store.username = username.replacingOccurrences(of: "@", with: "")
                    store.bio = bio
                }
            }
        }
        .navigationTitle("Мой профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = store.displayName; username = store.username; bio = store.bio }
    }
}

struct SimpleSettingsPage: View {
    let title: String
    let subtitle: String
    var body: some View {
        List { Section { Text(subtitle).foregroundStyle(EGTheme.muted) } }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Avatar

private struct AvatarView: View {
    let value: String
    let color: String
    let size: CGFloat
    var body: some View {
        Circle().fill(EGTheme.color(color).gradient).frame(width: size, height: size)
            .overlay {
                if value.contains(".") || value.contains("/") {
                    Image(systemName: value).font(.system(size: size * 0.38, weight: .semibold)).foregroundStyle(.white)
                } else {
                    Text(value).font(.system(size: size * 0.39, weight: .semibold)).foregroundStyle(.white)
                }
            }
            .accessibilityLabel("Аватар")
    }
}
