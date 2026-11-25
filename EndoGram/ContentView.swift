import SwiftUI

private enum EG {
    static let blue = Color(red: 0.10, green: 0.55, blue: 0.93)
    static let secondary = Color(red: 0.48, green: 0.52, blue: 0.57)
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let separator = Color(red: 0.90, green: 0.91, blue: 0.93)
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatsView()
                .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(0)
            ContactsView()
                .tabItem { Label("Контакты", systemImage: "person.crop.circle") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(EG.blue)
    }
}

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let message: String
    let time: String
    let symbol: String
    let color: Color
    var unread: Int = 0
    var online = false
    var pinned = false
}

private let demoChats: [Chat] = [
    Chat(name: "EndoGram", message: "Добро пожаловать в EndoGram!", time: "сейчас", symbol: "paperplane.fill", color: EG.blue, unread: 1, pinned: true),
    Chat(name: "Александр", message: "Давай, отлично 👍", time: "14:32", symbol: "person.fill", color: .orange, unread: 2, online: true, pinned: true),
    Chat(name: "Дизайн и идеи", message: "Мария: отправила макет", time: "13:48", symbol: "paintpalette.fill", color: .purple, unread: 0, pinned: true),
    Chat(name: "Илья", message: "Спасибо!", time: "12:16", symbol: "person.fill", color: .green, online: true),
    Chat(name: "Разработка", message: "Новый билд готов", time: "Вчера", symbol: "chevron.left.forwardslash.chevron.right", color: .indigo, unread: 4),
    Chat(name: "Мама", message: "Не забудь написать ❤️", time: "Вчера", symbol: "heart.fill", color: .pink)
]

struct ChatsView: View {
    @State private var search = ""
    @State private var showingCompose = false
    @State private var selectedChat: Chat?

    private var filtered: [Chat] {
        guard !search.isEmpty else { return demoChats }
        return demoChats.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.message.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 19))
                            .foregroundStyle(EG.secondary)
                            .frame(width: 48, height: 48)
                            .background(EG.background, in: Circle())
                        Text("Архив")
                            .font(.system(size: 16))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .listRowSeparator(.hidden)
                }
                Section {
                    ForEach(filtered) { chat in
                        Button {
                            selectedChat = chat
                        } label: {
                            ChatRow(chat: chat)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        .listRowSeparator(.visible)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Поиск")
            .navigationTitle("EndoGram")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {} label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCompose = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 19, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                NewMessageView()
            }
            .sheet(item: $selectedChat) { chat in
                NavigationStack { ConversationView(chat: chat) }
            }
        }
    }
}

private struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(chat.color.gradient)
                    .frame(width: 54, height: 54)
                    .overlay {
                        Image(systemName: chat.symbol)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                if chat.online {
                    Circle().fill(Color.green).frame(width: 13, height: 13)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(chat.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary)
                    Spacer()
                    Text(chat.time).font(.system(size: 12)).foregroundStyle(chat.unread > 0 ? EG.blue : EG.secondary)
                }
                HStack(spacing: 5) {
                    Text(chat.message)
                        .font(.system(size: 14))
                        .foregroundStyle(EG.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if chat.unread > 0 {
                        Text("\(chat.unread)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(EG.blue, in: Capsule())
                    } else if chat.pinned {
                        Image(systemName: "pin.fill").font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct ConversationView: View {
    let chat: Chat
    @State private var message = ""
    @State private var sentMessages: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Сегодня")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(EG.secondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.white.opacity(0.85), in: Capsule())
                    messageBubble("Привет! Это демонстрационный чат EndoGram.", outgoing: false, time: "12:30")
                    messageBubble("Проверяем интерфейс нового приложения 🚀", outgoing: true, time: "12:31")
                    messageBubble("Всё выглядит отлично!", outgoing: false, time: "12:32")
                    ForEach(Array(sentMessages.enumerated()), id: \.offset) { _, text in
                        messageBubble(text, outgoing: true, time: "сейчас")
                    }
                }
                .padding(14)
            }
            .background(Color(red: 0.91, green: 0.93, blue: 0.94))
            HStack(alignment: .bottom, spacing: 10) {
                Button {} label: { Image(systemName: "paperclip").font(.system(size: 21)).foregroundStyle(EG.blue) }
                TextField("Сообщение", text: $message, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.white, in: Capsule())
                Button {
                    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    sentMessages.append(trimmed)
                    message = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(EG.blue, in: Circle())
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(EG.background)
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: { Image(systemName: "ellipsis").foregroundStyle(EG.blue) }
            }
        }
    }

    private func messageBubble(_ text: String, outgoing: Bool, time: String) -> some View {
        HStack {
            if outgoing { Spacer(minLength: 50) }
            VStack(alignment: .trailing, spacing: 4) {
                Text(text).font(.system(size: 16)).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                Text(time).font(.system(size: 10)).foregroundStyle(EG.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(outgoing ? Color(red: 0.83, green: 0.94, blue: 0.79) : .white, in: RoundedRectangle(cornerRadius: 16))
            if !outgoing { Spacer(minLength: 50) }
        }
    }
}

struct ContactsView: View {
    private let contacts = [("Александр", "A", Color.orange), ("Илья", "И", Color.green), ("Мария", "М", Color.purple), ("Екатерина", "Е", Color.pink), ("Дмитрий", "Д", Color.indigo)]
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Пригласить друзей", systemImage: "person.badge.plus")
                        .foregroundStyle(EG.blue)
                    Label("Найти людей рядом", systemImage: "location")
                        .foregroundStyle(EG.blue)
                }
                Section("Контакты") {
                    ForEach(contacts.filter { search.isEmpty || $0.0.localizedCaseInsensitiveContains(search) }, id: \.0) { contact in
                        HStack(spacing: 12) {
                            Circle().fill(contact.2.gradient).frame(width: 46, height: 46)
                                .overlay(Text(contact.1).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(contact.0).font(.system(size: 16, weight: .medium))
                                Text("был(а) недавно").font(.system(size: 13)).foregroundStyle(EG.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, prompt: "Поиск контактов")
            .navigationTitle("Контакты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {} label: { Image(systemName: "plus").font(.system(size: 18, weight: .medium)) }
                }
            }
        }
    }
}

struct SettingsView: View {
    @State private var notifications = true
    @State private var sounds = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Circle().fill(EG.blue.gradient).frame(width: 62, height: 62)
                            .overlay(Text("E").font(.system(size: 26, weight: .bold)).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Мой профиль").font(.system(size: 18, weight: .semibold))
                            Text("@endogram_user").font(.system(size: 14)).foregroundStyle(EG.secondary)
                            Text("Изменить профиль").font(.system(size: 13)).foregroundStyle(EG.blue)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
                Section {
                    settingsRow("Уведомления", icon: "bell.badge", color: .red)
                    settingsRow("Конфиденциальность", icon: "lock", color: .blue)
                    settingsRow("Данные и память", icon: "externaldrive", color: .green)
                    settingsRow("Оформление", icon: "paintbrush", color: .purple)
                }
                Section {
                    Toggle(isOn: $notifications) {
                        Label("Уведомления", systemImage: "bell")
                    }
                    Toggle(isOn: $sounds) {
                        Label("Звуки", systemImage: "speaker.wave.2")
                    }
                }
                Section {
                    settingsRow("Помощь", icon: "questionmark.circle", color: .gray)
                    settingsRow("О приложении", icon: "info.circle", color: .gray)
                    HStack {
                        Text("EndoGram")
                        Spacer()
                        Text("Версия 0.1 (Prototype)").foregroundStyle(EG.secondary)
                    }
                    .font(.system(size: 13))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Настройки")
        }
    }

    private func settingsRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white).frame(width: 29, height: 29)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 7))
            Text(title).font(.system(size: 16))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
        }
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Новая группа", systemImage: "person.2")
                    Label("Новый секретный чат", systemImage: "lock")
                    Label("Новый канал", systemImage: "megaphone")
                }
                Section("Недавние контакты") {
                    Text("Здесь появятся контакты")
                        .foregroundStyle(EG.secondary)
                }
            }
            .navigationTitle("Новое сообщение")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Имя пользователя")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
