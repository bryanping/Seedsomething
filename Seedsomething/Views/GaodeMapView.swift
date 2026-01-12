//
//  GaodeMapView.swift
//  Seedsomething
//
//  高德地图视图包装器（需要集成高德地图 SDK 后使用）
//

import SwiftUI
import CoreLocation

// 注意：此文件需要在高德地图 SDK 集成后才能使用
// 集成步骤请参考 GAODE_MAP_SETUP.md

/*
#if canImport(MAMapKit)
import MAMapKit
import AMapFoundationKit

struct GaodeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [PlantRecord]
    var userLocation: CLLocationCoordinate2D?
    var onAnnotationTap: (PlantRecord) -> Void
    
    func makeUIView(context: Context) -> MAMapView {
        let mapView = MAMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userLocation.title = "我的位置"
        mapView.zoomLevel = 15
        return mapView
    }
    
    func updateUIView(_ mapView: MAMapView, context: Context) {
        // 更新地图中心
        let coordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        mapView.setCenter(coordinate, animated: true)
        
        // 更新标注
        mapView.removeAnnotations(mapView.annotations)
        
        // 添加用户位置标注
        if let userLocation = userLocation {
            let userAnnotation = MAPointAnnotation()
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "我的位置"
            mapView.addAnnotation(userAnnotation)
        }
        
        // 添加种草记录标注
        for record in annotations {
            let annotation = MAPointAnnotation()
            annotation.coordinate = record.coordinate.clLocationCoordinate2D
            annotation.title = "种草记录"
            annotation.subtitle = record.id
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MAMapViewDelegate {
        var parent: GaodeMapView
        
        init(_ parent: GaodeMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
            if let annotation = view.annotation as? MAPointAnnotation,
               let recordId = annotation.subtitle,
               let record = parent.annotations.first(where: { $0.id == recordId }) {
                parent.onAnnotationTap(record)
            }
        }
        
        func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
            if annotation.isKind(of: MAPointAnnotation.self) {
                let identifier = "annotationView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.image = UIImage(systemName: "leaf.fill")
                annotationView?.canShowCallout = true
                return annotationView
            }
            return nil
        }
    }
}
#endif
*/

// 占位视图（在高德地图 SDK 未集成时使用）
struct GaodeMapViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Text("高德地图 SDK 未集成")
                .foregroundColor(.gray)
        }
    }
}


