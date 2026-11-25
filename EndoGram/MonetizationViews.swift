import SwiftUI

private enum EGStoreStyle {
    static let blue = Color(red: 0.12, green: 0.56, blue: 0.96)
    static let gold = Color(red: 0.98, green: 0.70, blue: 0.20)
    static let ink = Color(red: 0.12, green: 0.15, blue: 0.19)
    static let muted = Color(red: 0.48, green: 0.52, blue: 0.57)
    static let surface = Color(red: 0.96, green: 0.97, blue: 0.98)
}

struct PremiumHubView: View {
    @AppStorage("eg_demo_premium") private var premiumEnabled = false
    @State private var showGift = false

    private let perks: [(String, String, String)] = [
        ("Без ограничений", "Загружайте большие файлы и отправляйте больше медиа", "arrow.up.arrow.down"),
        ("Быстрее загрузки", "Приоритетная скорость скачивания файлов", "bolt.fill"),
        ("Премиум-стикеры", "Эксклюзивные наборы и анимированные реакции", "face.smiling"),
        ("Расширенные истории", "Больше возможностей оформления историй", "circle.dashed"),
        ("Уникальный профиль", "Звёздочный значок и дополнительные оформления", "person.crop.circle.badge.checkmark"),
        ("Голос в текст", "Преобразование голосовых сообщений в текст", "waveform")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.25, green: 0.48, blue: 0.91), Color(red: 0.48, green: 0.32, blue: 0.84)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 66))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, EGStoreStyle.gold)
                        Text("EndoGram Premium")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Больше возможностей. Больше свободы.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.88))
                        if premiumEnabled {
                            Label("Премиум активен (демо)", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 13).padding(.vertical, 8)
                                .background(.white.opacity(0.18), in: Capsule())
                        } else {
                            Button {
                                premiumEnabled = true
                            } label: {
                                Text("Активировать демо Premium")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(EGStoreStyle.ink)
                                    .padding(.horizontal, 20).padding(.vertical, 12)
                                    .background(.white, in: Capsule())
                            }
                        }
                        Text("Демонстрационный режим · без оплаты")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.vertical, 28)
                }
                .frame(height: 275)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Что входит в Premium")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(EGStoreStyle.ink)
                    ForEach(perks, id: \.0) { perk in
                        HStack(spacing: 14) {
                            Image(systemName: perk.2)
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(EGStoreStyle.blue)
                                .frame(width: 42, height: 42)
                                .background(EGStoreStyle.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(perk.0).font(.system(size: 16, weight: .semibold))
                                Text(perk.1).font(.system(size: 13)).foregroundStyle(EGStoreStyle.muted)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))

                Button { showGift = true } label: {
                    HStack {
                        Image(systemName: "gift.fill").foregroundStyle(EGStoreStyle.gold)
                        Text("Подарить Premium").fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(EGStoreStyle.ink)
                    .padding(17)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                }
                .sheet(isPresented: $showGift) { PremiumGiftView() }
            }
            .padding(16)
        }
        .background(EGStoreStyle.surface)
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PremiumGiftView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var duration = "12 месяцев"
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Получатель") {
                    TextField("@username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Срок подарка") {
                    Picker("Период", selection: $duration) {
                        Text("3 месяца").tag("3 месяца")
                        Text("6 месяцев").tag("6 месяцев")
                        Text("12 месяцев").tag("12 месяцев")
                    }
                }
                Section {
                    Label("Подарок будет показан только в этом офлайн-прототипе.", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Button {
                    sent = true
                } label: {
                    Text("Отправить демо-подарок")
                        .frame(maxWidth: .infinity)
                }
                .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Подарить Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Закрыть") { dismiss() } }
            }
            .alert("Подарок создан", isPresented: $sent) {
                Button("Готово") { dismiss() }
            } message: {
                Text("Демо-подарок Premium (\(duration)) для \(username) сохранён локально в интерфейсе.")
            }
        }
    }
}

struct StarsHubView: View {
    @AppStorage("eg_demo_stars") private var stars = 250
    @State private var showInfo = false

    private let packs: [(String, Int, String)] = [
        ("Небольшой набор", 100, "100"),
        ("Популярный набор", 500, "500"),
        ("Большой набор", 1000, "1 000"),
        ("Максимальный набор", 2500, "2 500")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 62))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, EGStoreStyle.gold)
                    Text("\(stars)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Звёзд на демо-балансе")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 27)
                .background(LinearGradient(colors: [Color(red: 0.96, green: 0.65, blue: 0.18), Color(red: 0.95, green: 0.43, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))

                HStack {
                    Text("Пополнить баланс").font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle").foregroundStyle(EGStoreStyle.blue)
                    }
                }
                ForEach(packs, id: \.1) { pack in
                    Button {
                        stars += pack.1
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(EGStoreStyle.gold)
                                .frame(width: 42, height: 42)
                                .background(EGStoreStyle.gold.opacity(0.13), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pack.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(EGStoreStyle.ink)
                                Text("\(pack.2) ⭐").font(.system(size: 13)).foregroundStyle(EGStoreStyle.muted)
                            }
                            Spacer()
                            Text("Добавить")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 13).padding(.vertical, 8)
                                .background(EGStoreStyle.blue, in: Capsule())
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(.plain)
                }
                Text("Пополнение работает условно: баланс хранится на устройстве. Реальные платежи не подключены.")
                    .font(.system(size: 12))
                    .foregroundStyle(EGStoreStyle.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .background(EGStoreStyle.surface)
        .navigationTitle("Звёзды")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Демо-звёзды", isPresented: $showInfo) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text("Это локальный баланс для проверки интерфейса. Он не имеет денежной стоимости.")
        }
    }
}

struct GiftsHubView: View {
    @AppStorage("eg_demo_stars") private var stars = 250
    @State private var selectedGift: String?
    @State private var recipient = ""
    @State private var confirmation = false
    @State private var error = false

    private let gifts: [(String, String, Int, String)] = [
        ("Сердце", "heart.fill", 15, "Розовое сердце"),
        ("Мишка", "teddybear.fill", 25, "Мягкий сюрприз"),
        ("Цветы", "花", 50, "Букет цветов"),
        ("Ракета", "paperplane.fill", 75, "К новым высотам"),
        ("Трофей", "trophy.fill", 100, "Для победителя"),
        ("Алмаз", "diamond.fill", 150, "Особенный подарок"),
        ("Корона", "crown.fill", 250, "Королевский подарок"),
        ("Звезда", "star.fill", 500, "Самый яркий подарок")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Подарки").font(.system(size: 26, weight: .bold))
                        Text("Порадуйте друзей виртуальным подарком").font(.system(size: 13)).foregroundStyle(EGStoreStyle.muted)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill").foregroundStyle(EGStoreStyle.gold)
                        Text("\(stars)").fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(.white, in: Capsule())
                }

                TextField("Кому отправить? @username", text: $recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(gifts, id: \.0) { gift in
                        Button {
                            selectedGift = gift.0
                        } label: {
                            VStack(spacing: 9) {
                                ZStack {
                                    Circle().fill(EGStoreStyle.gold.opacity(0.13)).frame(width: 76, height: 76)
                                    if gift.1 == "花" {
                                        Text("💐").font(.system(size: 38))
                                    } else {
                                        Image(systemName: gift.1)
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundStyle(EGStoreStyle.gold)
                                    }
                                }
                                Text(gift.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(EGStoreStyle.ink)
                                Text("\(gift.2) ⭐").font(.system(size: 13, weight: .medium)).foregroundStyle(EGStoreStyle.muted)
                                Text(gift.3).font(.system(size: 11)).foregroundStyle(EGStoreStyle.muted).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selectedGift == gift.0 ? EGStoreStyle.blue : .clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let chosen = gifts.first(where: { $0.0 == selectedGift }) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Выбран подарок").font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(chosen.2) ⭐").foregroundStyle(EGStoreStyle.gold).fontWeight(.bold)
                        }
                        Button {
                            guard !recipient.trimmingCharacters(in: .whitespaces).isEmpty else { error = true; return }
                            guard stars >= chosen.2 else { error = true; return }
                            stars -= chosen.2
                            confirmation = true
                        } label: {
                            Text("Отправить подарок")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(EGStoreStyle.blue, in: Capsule())
                        }
                    }
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
                Text("Подарки демонстрационные: отправка и списание звёзд выполняются только локально на этом устройстве.")
                    .font(.system(size: 12)).foregroundStyle(EGStoreStyle.muted)
            }
            .padding(16)
        }
        .background(EGStoreStyle.surface)
        .navigationTitle("Подарки")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Подарок отправлен", isPresented: $confirmation) {
            Button("Отлично", role: .cancel) { selectedGift = nil }
        } message: {
            Text("Демо-подарок «\(selectedGift ?? "")» для \(recipient) добавлен локально.")
        }
        .alert("Не удалось отправить", isPresented: $error) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text(recipient.trimmingCharacters(in: .whitespaces).isEmpty ? "Укажите получателя." : "Недостаточно звёзд на демо-балансе.")
        }
    }
}
