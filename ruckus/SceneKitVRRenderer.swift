//
//  SceneKitVRRenderer.swift
//  ruckus
//
//  Created by Gareth on 06.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit

extension float4x4 {
    init(_ matrix: SCNMatrix4) {
        self.init([
            float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
            float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
            float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
            float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44)
            ])
    }
}

extension float4 {
    init(_ vector: SCNVector4) {
        self.init(vector.x, vector.y, vector.z, vector.w)
    }

    init(_ vector: SCNVector3) {
        self.init(vector.x, vector.y, vector.z, 1)
    }
}

extension SCNVector4 {
    init(_ vector: float4) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }

    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

extension SCNVector3 {
    init(_ vector: float4) {
        self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
    }
}

class SceneKitVRRenderer: NSObject, GVRCardboardViewDelegate {
    
    let scene: VRScene
    var renderer : [SCNRenderer?] = []
    var renderTime = 0.0 // seconds
    
    init(scene: VRScene) {
        self.scene = scene
    }
    
    
    func createRenderer() -> SCNRenderer {
        let renderer = SCNRenderer.init(context: EAGLContext.current(), options: nil)
        
//        renderer.pointOfView = camNodeGlobal
        renderer.scene = scene
        // comment this out if you would like custom lighting
        renderer.autoenablesDefaultLighting = true
        return renderer
    }
    
    
    func cardboardView(_ cardboardView: GVRCardboardView!, willStartDrawing headTransform: GVRHeadTransform!) {
        renderer.append(createRenderer())
        renderer.append(createRenderer())
        renderer.append(createRenderer())
    }
    
    
    func cardboardView(_ cardboardView: GVRCardboardView!, prepareDrawFrame headTransform: GVRHeadTransform!) {
        
//        prepareFrame(with: headTransform)
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        // can't get SCNRenderer to do this, has to do myself
        if let color = scene.background.contents as? UIColor {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            
            glClearColor(GLfloat(r), GLfloat(g), GLfloat(b), 1)
        }
        else {
            glClearColor(0, 0, 0, 1)
        }
        
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_SCISSOR_TEST))
        
        renderTime = CACurrentMediaTime()
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, draw eye: GVREye, with headTransform: GVRHeadTransform!) {
        
        let viewport = headTransform.viewport(for: eye)
        glViewport(GLint(viewport.origin.x), GLint(viewport.origin.y), GLint(viewport.size.width), GLint(viewport.size.height))
        glScissor(GLint(viewport.origin.x), GLint(viewport.origin.y), GLint(viewport.size.width), GLint(viewport.size.height))
        
        
        let projection_matrix = headTransform.projectionMatrix(for: eye, near: 0.1, far: 1000.0)
        let model_view_matrix = GLKMatrix4Multiply(headTransform.eye(fromHeadMatrix: eye), headTransform.headPoseInStartSpace())
        
        guard let eyeRenderer = renderer[eye.rawValue] else {
            fatalError("no eye renderer for eye")
        }
        
        eyeRenderer.pointOfView?.camera?.projectionTransform = SCNMatrix4FromGLKMatrix4(projection_matrix)
        eyeRenderer.pointOfView?.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Transpose(model_view_matrix))
        
        if glGetError() == GLenum(GL_NO_ERROR) {
            eyeRenderer.render(atTime: renderTime)
        }
        
    }
    
    
    
    
}
