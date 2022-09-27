import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
  @IBOutlet private var mapView: MKMapView!
  private var artworks: [Artwork] = []
  let options: MKMapSnapshotter.Options = .init()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    showMapWithPolygon()
    
//    mapView.isHidden = true
//    takeSnapShot()
  }

  @IBOutlet weak var mapPreviewImageView: UIImageView!
  
  let imageCache = NSCache<NSString, UIImage>()
  let imageCacheKey: NSString = "CachedMapSnapshot" // this should be object specific name

  private func cacheImage(image: UIImage) {
      imageCache.setObject(image, forKey: imageCacheKey)
  }

  private func cachedImage() -> UIImage? {
      return imageCache.object(forKey: imageCacheKey)
  }
  
  //Check if point is inside polygon
  func pointIsInside(point: MKMapPoint, polygon: MKPolygon) -> Bool {
      let mapRect = MKMapRect(x: point.x, y: point.y, width: 0.0001, height: 0.0001)
      return polygon.intersects(mapRect)
  }
  
  func checkIf(_ location: CLLocationCoordinate2D, areInside polygon: MKPolygon) -> Bool {
      let polygonRenderer = MKPolygonRenderer(polygon: polygon)
      let mapPoint = MKMapPoint(location)
      let polygonPoint = polygonRenderer.point(for: mapPoint)

      return polygonRenderer.path.contains(polygonPoint)
  }
  
  func drawLineOnImage(points: [CLLocation], snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
      let image = snapshot.image

      UIGraphicsBeginImageContextWithOptions(self.mapPreviewImageView.frame.size, true, 0)
      image.draw(at: CGPoint.zero)
      let context = UIGraphicsGetCurrentContext()
      context!.setLineWidth(2.0)
      context!.setStrokeColor(UIColor.orange.cgColor)

      context!.move(to: snapshot.point(for: points[0].coordinate))
      for i in 0...points.count-1 {
        context!.addLine(to: snapshot.point(for: points[i].coordinate))
        context!.move(to: snapshot.point(for: points[i].coordinate))
      }
      context!.addLine(to: snapshot.point(for: points[0].coordinate))
      context!.strokePath()
      let resultImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return resultImage!
  }
  
  func takeSnapShot() {
      let points = createPoints()
      let options = MKMapSnapshotter.Options()
      options.region = MKCoordinateRegion(center: points[0].coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
      options.size = mapPreviewImageView.frame.size
   
      options.showsBuildings = true
    options.mapType = .mutedStandard
      options.scale = UIScreen.main.scale
      let snapShotter = MKMapSnapshotter(options: options)
      snapShotter.start() {[weak self] snapshot, error in
          guard let snapshot = snapshot, let self = self else {
              return
          }
        self.mapPreviewImageView.image = self.drawLineOnImage(points: points, snapshot: snapshot)
      }
   }
  
  private func showMapWithPolygon() {
    let initialLocation = CLLocation(latitude: 52.499967, longitude: 13.4632702)
   
    mapView.centerToLocation(initialLocation)
    
    let startingPointCenter = CLLocation(latitude: 52.4983, longitude: 13.4066)
    let region = MKCoordinateRegion(
      center: startingPointCenter.coordinate,
      latitudinalMeters: 50000,
      longitudinalMeters: 60000)
    mapView.setCameraBoundary(
      MKMapView.CameraBoundary(coordinateRegion: region),
      animated: true)
    
    let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 1000000)
    mapView.setCameraZoomRange(zoomRange, animated: true)
    mapView.delegate = self
    
//    mapView.register(
//      ArtworkView.self,
//      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    
    loadInitialData()
    mapView.addAnnotations(artworks)
    
    let rider = CLLocation(latitude: 52.493552, longitude: 13.4621654)
    let points = createPoints()
    showStartingArea(points)
    
    let closestPoint = getClosetPoint(points, from: rider)
    let line = drawRoute(from: rider, to: closestPoint)
    mapView.addOverlay(line)
  }

  private func createPoints() -> [CLLocation] {
    let latitude: [String] = [
               "52.46523208572938",
               "52.46531705969792",
               "52.46559567511719",
               "52.46588450185006",
               "52.46643273634816",
               "52.46791236348105",
               "52.46937478427294",
               "52.47075546098522",
               "52.47282231025754",
               "52.47488579494794",
               "52.47773865231441",
               "52.48033077334113",
               "52.48288190514786",
               "52.48380765947311",
               "52.48263892714145",
               "52.48913560021965",
               "52.48497864493917",
               "52.47928790150927",
               "52.47515046294253",
               "52.47273081542615",
               "52.46894872647162",
               "52.46600338189253",
               "52.46523208572938",
    ]
    
    let longitude: [String] = ["13.4293270111084",
               "13.4324149042368",
               "13.43451105058194",
               "13.43790270388127",
                 "13.44076663255692",
                 "13.44249397516251",
                 "13.44330668449402",
                 "13.44398126006127",
                 "13.4444560110569",
                 "13.44381093978882",
                 "13.44307199120522",
                 "13.43993447721005",
                 "13.43519300222397",
                 "13.4275346249342",
                 "13.42189528048039",
                 "13.39991140295752",
                 "13.38915691827424",
                 "13.39416743139737",
                 "13.41293670237065",
                 "13.41322638094426",
                 "13.41557465493679",
                 "13.42167869210244",
                 "13.4293270111084"
    ]
    
    var points = [CLLocation]()
    latitude.enumerated().forEach {(index, _) in
      guard let lat = Double(latitude[index]),
            let longi = Double(longitude[index]) else { return }
      points.append(CLLocation(latitude: lat, longitude: longi))
    }
    return points
  }
  
  private func drawRoute(from pointA: CLLocation, to pointB: CLLocation) -> MKPolyline {
    let routeArray = [pointA.coordinate, pointB.coordinate]
    let myPolyline = MKPolyline(coordinates: routeArray, count: routeArray.count)
    mapView.addOverlay(myPolyline)
    return myPolyline
  }
  
  private func showStartingArea(_ points: [CLLocation]) {
    let places: [Place] = points.map {
      return Place(title: "Test 1", subtitle: "", coordinate: $0.coordinate)
    }
    var locations = places.map { $0.coordinate }
    let polygon = MKPolygon(coordinates: &locations, count: locations.count)
    
    mapView.addOverlay(polygon)
  }
  
  private func getClosetPoint(_ points: [CLLocation], from rider: CLLocation) -> CLLocation {
    var index = 0
    var min = points[0].distance(from: rider)
    points.enumerated().forEach {
      let currentDistance = $1.distance(from: rider)
      if min > currentDistance {
        index = $0
        min = currentDistance
      }
    }
    let closetPoint = points[index]
    return closetPoint
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKCircle {
          let renderer = MKCircleRenderer(overlay: overlay)
          renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
          renderer.strokeColor = UIColor.blue
          renderer.lineWidth = 2
          return renderer
      
      } else if overlay is MKPolyline {
          let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.darkGray
          renderer.lineWidth = 3
          return renderer
      
      } else if overlay is MKPolygon {
          let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
          renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
          renderer.strokeColor = UIColor.orange
          renderer.lineWidth = 2
          return renderer
      }
      
      return MKOverlayRenderer()
  }

  
  private func loadInitialData() {
    guard
//      let fileName = Bundle.main.url(forResource: "PublicArt", withExtension: "geojson"),
      let fileName = Bundle.main.url(forResource: "TestKreuzberg", withExtension: "geojson"),
      let artworkData = try? Data(contentsOf: fileName)
      else {
        return
    }
    
    do {
      let features = try MKGeoJSONDecoder()
        .decode(artworkData)
        .compactMap { $0 as? MKGeoJSONFeature }
      let validWorks = features.compactMap(Artwork.init)
      artworks.append(contentsOf: validWorks)
    } catch {
      print("Unexpected error: \(error).")
    }
  }
}

private extension MKMapView {
  func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(
    _ mapView: MKMapView,
    annotationView view: MKAnnotationView,
    calloutAccessoryControlTapped control: UIControl
  ) {
    guard let artwork = view.annotation as? Artwork else {
      return
    }
    
    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    artwork.mapItem?.openInMaps(launchOptions: launchOptions)
  }
}
