import CoreLocation
import libxml2

//struct gpx_open {
//    var text = "Hello, World!"
//}

class GPXParserDelegate: NSObject, XMLParserDelegate {
  let finishedSempaphore: DispatchSemaphore
  
  var elementDeclarations: [(String, String)] = []
  var internalEntities: [(String, String)] = []
  var elements: [(String, String)] = []
  
  init(finishedSemaphore: DispatchSemaphore) {
    self.finishedSempaphore = finishedSemaphore
  }
  
  func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
    print("name: \(elementName)\n-model: \(model)")
    elementDeclarations.append((elementName, model))
  }
  
  func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
    internalEntities.append((name, value ?? ""))
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    elements.append((elementName, qName ?? ""))
  }
  
  func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    finishedSempaphore.signal()
  }
  
  func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
    finishedSempaphore.signal()
  }
  
  func parserDidEndDocument(_ parser: XMLParser) {
    finishedSempaphore.signal()
  }
}

extension CLLocationCoordinate2D {
  
  static func location(gpx: Data) -> [(String, String)] {
    print(String(data: gpx, encoding: .utf8))
    let parser = XMLParser(data: gpx)
    let finishedSemaphore = DispatchSemaphore(value: 0)
    let delegate = GPXParserDelegate(finishedSemaphore: finishedSemaphore)
    parser.delegate = delegate
    parser.parse()
    let waitResult = finishedSemaphore.wait(wallTimeout: .now() + .seconds(5))
    if waitResult == .timedOut {
      print("parse timed out")
    }
    return delegate.elements
  }
  
   static func gpxData(gpxFilename: String) throws -> Data {
     guard let url = Bundle.main.url(forResource: gpxFilename, withExtension: "gpx") else {
       throw URLError(.fileDoesNotExist)
     }
     let data = try Data(contentsOf: url)
     return data
   }
  
  static func location(gpxFilename: String) throws -> [(String, String)] {
    let data = try gpxData(gpxFilename: gpxFilename)
    return CLLocationCoordinate2D.location(gpx: data)
  }
  
}
