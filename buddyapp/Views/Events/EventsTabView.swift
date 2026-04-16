import SwiftUI

struct EventsTabView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = EventsViewModel()

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.upcomingEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "No upcoming events",
                        message: "Join groups to see events here. Events from all your groups will appear in one place."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groupedEvents.keys.sorted(), id: \.self) { dateKey in
                                Section {
                                    ForEach(groupedEvents[dateKey] ?? []) { event in
                                        NavigationLink(value: event) {
                                            EventCard(event: event, currentUserID: authService.currentUser?.id ?? "")
                                                .padding(.horizontal, 16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    Text(dateKey)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        await loadEvents()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
        .task {
            await loadEvents()
        }
        .onChange(of: authService.currentUser?.groupIDs) { _, groupIDs in
            Task { await loadEvents() }
        }
    }

    private func loadEvents() async {
        let groupIDs = authService.currentUser?.groupIDs ?? []
        await viewModel.loadUpcomingEvents(groupIDs: groupIDs)
    }

    private var groupedEvents: [String: [Event]] {
        let formatter = RelativeDateFormatter()
        return Dictionary(grouping: viewModel.upcomingEvents) { event in
            formatDateSection(event.dateTime)
        }
    }

    private func formatDateSection(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
private class RelativeDateFormatter {}

