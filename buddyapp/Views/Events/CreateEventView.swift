import SwiftUI
import MapKit

struct CreateEventView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    let group: Group

    @State private var viewModel = CreateEventViewModel()
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3316, longitude: -122.0307),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showMapPreview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    FormField(label: "Event Title") {
                        TextField("e.g. Saturday Hike", text: $viewModel.title)
                            .autocorrectionDisabled()
                    }

                    // Description
                    FormField(label: "Description") {
                        TextField("What should people know?", text: $viewModel.description, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    // Address
                    VStack(alignment: .leading, spacing: 8) {
                        FormField(label: "Address") {
                            HStack(spacing: 10) {
                                TextField("Enter location", text: $viewModel.address)
                                    .autocorrectionDisabled()

                                if !viewModel.address.isEmpty {
                                    Button {
                                        lookupAddress()
                                    } label: {
                                        Image(systemName: "map")
                                            .foregroundStyle(.accent)
                                    }
                                }
                            }
                        }

                        // Map preview
                        if showMapPreview {
                            Map(position: createEventMapCameraBinding) {
                                Marker("", coordinate: mapRegion.center)
                                    .tint(Color.accentColor)
                            }
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .disabled(true)
                        }
                    }

                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "Select date and time",
                            selection: $viewModel.dateTime,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    }

                    PrimaryButton(
                        title: "Create Event",
                        isLoading: viewModel.isLoading
                    ) {
                        await create()
                    }
                    .disabled(!viewModel.isValid)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var createEventMapCameraBinding: Binding<MapCameraPosition> {
        Binding(
            get: { MapCameraPosition.region(mapRegion) },
            set: { _ in }
        )
    }

    private func lookupAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(viewModel.address) { placemarks, _ in
            if let coordinate = placemarks?.first?.location?.coordinate {
                withAnimation {
                    mapRegion = MKCoordinateRegion(center: coordinate, span: mapRegion.span)
                    showMapPreview = true
                }
            }
        }
    }

    private func create() async {
        guard let uid = authService.currentUser?.id,
              let groupID = group.id else { return }
        do {
            _ = try await viewModel.createEvent(
                groupID: groupID,
                groupName: group.name,
                creatorID: uid
            )
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
