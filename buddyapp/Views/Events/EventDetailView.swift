import SwiftUI
import MapKit

struct EventDetailView: View {
    @Environment(AuthService.self) private var authService
    let event: Event

    @State private var viewModel: EventDetailViewModel
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3316, longitude: -122.0307),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var mapLoaded = false

    init(event: Event) {
        self.event = event
        self._viewModel = State(initialValue: EventDetailViewModel(event: event))
    }

    var currentUserID: String { authService.currentUser?.id ?? "" }
    var myRSVP: RSVPStatus? { viewModel.event.rsvpStatus(for: currentUserID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Event header
                eventHeader

                // RSVP buttons
                rsvpSection

                // Details
                detailsSection

                // Map
                if !viewModel.event.address.isEmpty {
                    mapSection
                }

                // Attendees
                attendeesSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.event.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCreator()
            lookupAddress()
        }
    }

    // MARK: - Event Header

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Date block
                VStack(spacing: 4) {
                    Text(viewModel.event.dateTime, format: .dateTime.month(.abbreviated))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.accent)
                        .textCase(.uppercase)
                    Text(viewModel.event.dateTime, format: .dateTime.day())
                        .font(.system(size: 36, weight: .bold))
                }
                .frame(width: 60)
                .padding(14)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.event.title)
                        .font(.title3.bold())

                    Label(viewModel.event.groupName, systemImage: "person.3")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label(viewModel.event.dateTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !viewModel.creatorName.isEmpty {
                Label("Created by \(viewModel.creatorName)", systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - RSVP Section

    private var rsvpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your RSVP")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                ForEach(RSVPStatus.allCases, id: \.self) { status in
                    RSVPButton(
                        status: status,
                        isSelected: myRSVP == status,
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.updateRSVP(userID: currentUserID, status: status)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.event.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)

                    Text(viewModel.event.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            }

            if !viewModel.event.address.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.accent)
                    Text(viewModel.event.address)
                        .font(.subheadline)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
                .padding(.horizontal, 20)

            if mapLoaded {
                Map(position: eventMapCameraBinding) {
                    Marker("", coordinate: mapRegion.center)
                        .tint(Color.accentColor)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .disabled(true)
            }
        }
    }

    // MARK: - Attendees

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendees")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 20) {
                AttendeeCount(count: viewModel.event.goingCount, status: .going)
                AttendeeCount(count: viewModel.event.maybeCount, status: .maybe)
                AttendeeCount(count: viewModel.event.notGoingCount, status: .notGoing)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private func lookupAddress() {
        guard !viewModel.event.address.isEmpty else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(viewModel.event.address) { placemarks, _ in
            if let coordinate = placemarks?.first?.location?.coordinate {
                mapRegion = MKCoordinateRegion(center: coordinate, span: mapRegion.span)
                withAnimation { mapLoaded = true }
            }
        }
    }

    private var eventMapCameraBinding: Binding<MapCameraPosition> {
        Binding(
            get: { MapCameraPosition.region(mapRegion) },
            set: { _ in }
        )
    }
}

struct RSVPButton: View {
    let status: RSVPStatus
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void

    var color: Color {
        switch status {
        case .going: return .green
        case .notGoing: return .red
        case .maybe: return .orange
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : color)
                Text(status.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? color : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color(.separator), lineWidth: isSelected ? 0 : 0.5)
            )
        }
        .disabled(isLoading)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct AttendeeCount: View {
    let count: Int
    let status: RSVPStatus

    var label: String { status.displayName }

    var color: Color {
        switch status {
        case .going: return .green
        case .notGoing: return .red
        case .maybe: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
