//
//  VRControllerProtocal.h
//  ruckus
//
//  Created by Gareth on 05.01.18.
//  Copyright © 2018 Gareth. All rights reserved.
//

@import SceneKit;

@protocol VRControllerProtocol <NSObject>

- (nonnull instancetype)init;
@property (nonatomic, assign, readonly) SCNScene * _Nonnull scene;
- (void)prepareFrameWithHeadTransform:(GVRHeadTransform * _Nonnull)headTransform;
- (void)eventTriggered;

@end
