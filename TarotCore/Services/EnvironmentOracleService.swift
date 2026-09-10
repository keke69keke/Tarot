import Foundation
import CoreLocation

/// Service that provides spiritual insights based on the user's physical environment.
public final class EnvironmentOracleService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published public private(set) var currentEnvironment: EnvironmentType = .unknown

    public enum EnvironmentType: String {
        case water = "Agua"
        case urban = "Ciudad"
        case forest = "Bosque"
        case mountain = "Montaña"
        case unknown = "Desconocido"
    }

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startMonitoring() {
        locationManager.startUpdatingLocation()
    }

    public func stopMonitoring() {
        locationManager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        analyzeLocation(location)
    }

    private func analyzeLocation(_ location: CLLocation) {
        // In a real app, this would use a Reverse Geocoding service or a Land-Use API
        // Here we simulate detection for demonstration
        let randomType = [EnvironmentType.water, .urban, .forest, .mountain].randomElement()!
        self.currentEnvironment = randomType
    }

    public func getEnvironmentalSuggestion() -> String? {
        switch currentEnvironment {
        case .water:
            return "Estás cerca del agua; la energía de las Copas está amplificada aquí. ¿Deseas una lectura sobre tus emociones?"
        case .urban:
            return "El ruido de la ciudad es fuerte. Es un buen momento para una lectura de Espadas y traer claridad mental."
        case .forest:
            return "Rodeado de naturaleza, la energía de los Bastos fluye. ¿Buscas inspiración o acción hoy?"
        case .mountain:
            return "En las alturas, la estabilidad de los Oros es predominante. ¿Deseas analizar tu seguridad material?"
        case .unknown:
            return nil
        }
    }
}
