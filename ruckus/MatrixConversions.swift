//
//  MatrixConversions.swift
//  VRBoxing
//
//  Created by Gareth on 28.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import GameKit

class MatrixConversions {
    static let sharedInstance = MatrixConversions()
    
    
    func convertToFloat3x3(float4x4: simd_float4x4) -> simd_float3x3 {
        let column0 = convertToFloat3 ( float4: float4x4.columns.0 )
        let column1 = convertToFloat3 ( float4: float4x4.columns.1 )
        let column2 = convertToFloat3 ( float4: float4x4.columns.2 )
        
        return simd_float3x3.init(column0, column1, column2)
    }
    
    func convertToFloat3(float4: simd_float4) -> simd_float3 {
        return simd_float3.init(float4.x, float4.y, float4.z)
    }
    
    func convertToFloat4x4(float3x3: simd_float3x3) -> simd_float4x4 {
        let column0 = convertToFloat4 ( float3: float3x3.columns.0 )
        let column1 = convertToFloat4 ( float3: float3x3.columns.1 )
        let column2 = convertToFloat4 ( float3: float3x3.columns.2 )
        let identity3 = simd_float4.init(x: 0, y: 0, z: 0, w: 1)
        
        return simd_float4x4.init(column0, column1, column2, identity3)
    }
    
    func convertToFloat4(float3: simd_float3) -> simd_float4 {
        return simd_float4.init(float3.x, float3.y, float3.z, 0)
    }
}
