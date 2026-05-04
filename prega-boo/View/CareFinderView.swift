import CoreLocation
import MapKit
import SwiftUI

private func coordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
    let count = polyline.pointCount
    guard count > 0 else { return [] }
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
    polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
    return coords
}

private func regionFittingCoordinates(_ coordinates: [CLLocationCoordinate2D], paddingFactor: Double = 1.28) -> MKCoordinateRegion {
    guard let first = coordinates.first else {
        return MKCoordinateRegion(
            center: .init(latitude: 6.92, longitude: 79.88),
            span: .init(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    }
    var minLat = first.latitude
    var maxLat = first.latitude
    var minLon = first.longitude
    var maxLon = first.longitude
    for c in coordinates {
        minLat = min(minLat, c.latitude)
        maxLat = max(maxLat, c.latitude)
        minLon = min(minLon, c.longitude)
        maxLon = max(maxLon, c.longitude)
    }
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
    let span = MKCoordinateSpan(
        latitudeDelta: max(abs(maxLat - minLat) * paddingFactor, 0.015),
        longitudeDelta: max(abs(maxLon - minLon) * paddingFactor, 0.015)
    )
    return MKCoordinateRegion(center: center, span: span)
}

private enum CareFilter: String, CaseIterable {
    case all = "All Facilities"
    case hospitals = "Hospitals"
    case maternal = "Maternal Centers"
}

struct CareFinderView: View {
    let accentColor: Color

    @Environment(\.openURL) private var openURL
    @StateObject private var locationManager = UserLocationManager()
    @State private var facilities: [CareFacility] = CareFacilitiesLoader.loadFromBundle()
    @State private var filter: CareFilter = .all
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showGrid = false
    @State private var sheetHeightFraction: CGFloat = 0.42
    @State private var selectedFacilityId: String?
    @State private var didCenterOnUser = false
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.92, longitude: 79.88),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var activeRouteFacility: CareFacility?
    @State private var routeSummary: String?
    @State private var isCalculatingRoute = false
    @State private var routeErrorMessage: String?
    @State private var routeIsApproximate = false

    private let nearbyRadiusMeters: CLLocationDistance = 5000

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    mapSection
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                            .allowsHitTesting(false)
                        bottomSheetPanel(mapAreaHeight: h)
                    }
                }
            }
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        .onAppear {
            locationManager.requestWhenInUseAndStart()
        }
        .onChange(of: locationManager.location) { _, newLoc in
            guard !didCenterOnUser, let newLoc else { return }
            didCenterOnUser = true
            withAnimation(.easeInOut(duration: 0.45)) {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: newLoc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            }
        }
        .alert("Directions", isPresented: Binding(
            get: { routeErrorMessage != nil },
            set: { if !$0 { routeErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { routeErrorMessage = nil }
        } message: {
            Text(routeErrorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.28)) { isSearching.toggle() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }

            if isSearching {
                TextField("Search hospitals & centers", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
            } else {
                Text("Care Finder")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.78))
            }

            Spacer(minLength: 0)

            Circle()
                .fill(accentColor.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CareFilter.allCases, id: \.self) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(filter == item ? Color.white : Color.black.opacity(0.65))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(filter == item ? accentColor : Color.white)
                                    .shadow(color: filter == item ? accentColor.opacity(0.25) : .clear, radius: 6, y: 2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(filter == item ? 0 : 0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    }

    private var mapSection: some View {
        ZStack(alignment: .top) {
            Map(position: $mapPosition) {
                if routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(accentColor, lineWidth: 5)
                }
                ForEach(filteredForMap) { facility in
                    Annotation(facility.shortName, coordinate: facility.coordinate) {
                        mapPin(facility: facility, isSelected: selectedFacilityId == facility.id)
                    }
                }
                if let user = locationManager.location?.coordinate {
                    Annotation("", coordinate: user) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.25))
                                .frame(width: 22, height: 22)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)

            if isCalculatingRoute {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(accentColor)
                    Text("Calculating route…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 12)
            } else if let facility = activeRouteFacility, let summary = routeSummary {
                routeBanner(facility: facility, summary: summary)
            }
        }
    }

    private func routeBanner(facility: CareFacility, summary: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("To \(facility.shortName)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(summary + (routeIsApproximate ? " · straight line" : ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            Spacer(minLength: 8)
            Button {
                clearInAppRoute()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(accentColor.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private func clearInAppRoute() {
        withAnimation(.easeOut(duration: 0.25)) {
            routeCoordinates = []
            activeRouteFacility = nil
            routeSummary = nil
            routeIsApproximate = false
        }
    }

    private func mapPin(facility: CareFacility, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Text(facility.shortName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(accentColor)
                )
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                    .shadow(color: accentColor.opacity(0.45), radius: 4, y: 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func bottomSheetPanel(mapAreaHeight: CGFloat) -> some View {
        let sheetH = max(mapAreaHeight * sheetHeightFraction, 260)
        return VStack(spacing: 0) {
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let delta = -value.translation.height / max(mapAreaHeight, 1)
                            sheetHeightFraction = min(max(sheetHeightFraction + delta, 0.28), 0.62)
                        }
                )

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby Care")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.78))
                    Text(sheetSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.32)) { showGrid.toggle() }
                } label: {
                    Text(showGrid ? "See List" : "See Grid")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            if showGrid {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(displayedFacilities) { facility in
                            gridCell(facility)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedFacilities) { facility in
                            facilityRow(facility)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(height: sheetH, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: -4)
        )
    }

    private var sheetSubtitle: String {
        let n = nearbyFiltered.count
        if locationManager.location != nil {
            if n == 0, !displayedFacilities.isEmpty {
                return "None within 5km — showing nearest care"
            }
            return "\(n) facilities found within 5km"
        }
        return "\(displayedFacilities.count) facilities — enable location for distances"
    }

    private var filteredForMap: [CareFacility] {
        var list = facilities
        switch filter {
        case .all: break
        case .hospitals: list = list.filter { $0.kind == .hospital }
        case .maternal: list = list.filter { $0.kind == .maternal }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.area.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var nearbyFiltered: [CareFacility] {
        let base = filteredForMap
        guard let loc = locationManager.location else {
            return base.sorted { $0.name < $1.name }
        }
        return base
            .filter { f in
                (f.distanceMeters(from: loc) ?? .greatestFiniteMagnitude) <= nearbyRadiusMeters
            }
            .sorted { (a, b) in
                (a.distanceMeters(from: loc) ?? 0) < (b.distanceMeters(from: loc) ?? 0)
            }
    }

    /// List shown in the sheet: within 5km when possible; otherwise nearest facilities (simulator / abroad).
    private var displayedFacilities: [CareFacility] {
        let base = filteredForMap
        guard let loc = locationManager.location else {
            return base.sorted { $0.name < $1.name }
        }
        let within = nearbyFiltered
        if !within.isEmpty { return within }
        return base.sorted { (a, b) in
            (a.distanceMeters(from: loc) ?? 0) < (b.distanceMeters(from: loc) ?? 0)
        }
    }

    private func facilityRow(_ facility: CareFacility) -> some View {
        let dist = formattedDistance(for: facility)
        let open = facility.isOpenNow()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: facility.kind == .maternal ? "figure.and.child.holdinghands" : "cross.case.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(accentColor)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(facility.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Text(open ? "Open Now" : "Closed")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(open ? Color.green.opacity(0.9) : Color.red.opacity(0.75))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(open ? Color.green.opacity(0.15) : Color.red.opacity(0.12))
                            )
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.35))
                        Text("\(dist) • \(facility.area)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.45))
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    showInAppDirections(to: facility)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 15, weight: .bold))
                        Text("Directions")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(isCalculatingRoute)

                Button {
                    dial(facility.phone)
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(accentColor.opacity(0.35), lineWidth: 1.5)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.99, green: 0.99, blue: 1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .onTapGesture {
            selectedFacilityId = facility.id
            withAnimation(.easeInOut(duration: 0.35)) {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: facility.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                    )
                )
            }
        }
    }

    private func gridCell(_ facility: CareFacility) -> some View {
        let open = facility.isOpenNow()
        return VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.12))
                .frame(height: 72)
                .overlay(
                    Image(systemName: facility.kind == .maternal ? "figure.and.child.holdinghands" : "cross.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(accentColor)
                )
            Text(facility.shortName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.78))
                .lineLimit(2)
            Text(formattedDistance(for: facility))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.4))
            Text(open ? "Open" : "Closed")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(open ? .green : .red)
            Button {
                showInAppDirections(to: facility)
            } label: {
                Text("Directions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isCalculatingRoute)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.99, green: 0.99, blue: 1)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.06)))
        .onTapGesture {
            selectedFacilityId = facility.id
        }
    }

    private func formattedDistance(for facility: CareFacility) -> String {
        guard let m = facility.distanceMeters(from: locationManager.location) else {
            return "— km"
        }
        let km = m / 1000
        if km < 1 {
            return String(format: "%.1f km", km)
        }
        return String(format: "%.1f km", km)
    }

    /// Turn-by-turn path inside the app using MapKit routing (driving). Falls back to a straight geodesic if Apple cannot build a road route.
    private func showInAppDirections(to facility: CareFacility) {
        guard let userLoc = locationManager.location else {
            routeErrorMessage = "Turn on location services to see a route on the map."
            return
        }

        routeErrorMessage = nil
        routeIsApproximate = false
        routeCoordinates = []
        activeRouteFacility = nil
        routeSummary = nil
        isCalculatingRoute = true
        selectedFacilityId = facility.id

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: facility.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isCalculatingRoute = false

                if let route = response?.routes.first {
                    let coords = coordinates(from: route.polyline)
                    self.routeCoordinates = coords
                    self.activeRouteFacility = facility
                    self.routeIsApproximate = false
                    let seconds = route.expectedTravelTime
                    let distKm = route.distance / 1000
                    self.routeSummary = Self.formatRouteSummary(travelTime: seconds, distanceKm: distKm)
                    withAnimation(.easeInOut(duration: 0.45)) {
                        self.mapPosition = .region(regionFittingCoordinates(coords))
                    }
                    return
                }

                let straight = [userLoc.coordinate, facility.coordinate]
                self.routeCoordinates = straight
                self.activeRouteFacility = facility
                self.routeIsApproximate = true
                let straightMeters = userLoc.distance(from: CLLocation(latitude: facility.latitude, longitude: facility.longitude))
                self.routeSummary = String(format: "≈ %.0f km (direct)", straightMeters / 1000)
                withAnimation(.easeInOut(duration: 0.45)) {
                    self.mapPosition = .region(regionFittingCoordinates(straight))
                }
            }
        }
    }

    private static func formatRouteSummary(travelTime: TimeInterval, distanceKm: Double) -> String {
        let totalMinutes = max(Int(travelTime / 60), 1)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return String(format: "%d hr %d min · %.0f km", hours, mins, distanceKm)
        }
        return String(format: "%d min · %.1f km", mins, distanceKm)
    }

    private func dial(_ phone: String) {
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        openURL(url)
    }
}

#Preview {
    CareFinderView(accentColor: Color(red: 0.94, green: 0.39, blue: 0.45))
}
