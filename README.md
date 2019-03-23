# MultipeerLiveKit
![](https://img.shields.io/badge/License-MIT-Purple.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage)
![](https://img.shields.io/badge/Swift-4.2-orange.svg)
![](https://img.shields.io/badge/platforms-iOS-lightgrey.svg)

## Overview

[Multipeer Connectivity](https://developer.apple.com/documentation/multipeerconnectivity) Wrapper.



## Description

This library provides things Live Camera and Like a Text Chat.

## Demo
<img src="https://github.com/hayao11/MultipeerLiveKit/blob/for_gif/demo.gif" height="480px"> 


## Requirement

- Swift 4.2+
- iOS 10.0+

## Usage

When using this library, you need to define MCSessionManager and LivePresenter.


### #MCSessionManager#
MCSessionManager is a class for establishing a connection.

``` swift
import MultipeerLiveKit

let displayName = UIDevice.current.name
let serviceType = "YourServiceType"
self.mcSessionManager = MCSessionManager.init(displayName: displayName, serviceType: serviceType)

```

It is necessary to decide the transmission / reception protocol of data, and ".textAndVideo" is specified by default. If you want to select only video data, please specify ".videoOnly". At that time, "-V" is added to the end of the service Type.

``` swift
self.mcSessionManager = MCSessionManager.init(displayName: displayName, serviceType: serviceType, serviceProtocol: .videoOnly)

```

#### When you want to. Set true for start. Set false for stop
``` swift
mcSessionManager.needsToRunSession = true
mcSessionManager.needsAdvertising  = true
mcSessionManager.needsBrowsing     = true

```


#### Get the target's MCPeerID and state in relation to the connection

``` swift
mcSessionManager.onStateChanaged(connecting: { (targetPeerID, state) in

   //Called when connection state changes
   switch state {
   case .tryConnecting:break
   case .connected:break
   case .connectionFail:break
   }
   
}) {(foundPeerIDs) in

   //It is called when browsing is started or when an MCPeerID of the same service type is found.
   foundPeerIDs.forEach {
      self.mcSessionManager.inviteTo(peerID: $0, timeout: 10)
   }
   
}

```

#### Get state related to connection
``` swift
mcSessionManager.onRunStateChange { (rollType, isRun) in

  switch rollType {
  case .advertising:break
  case .browsing:break
  case .connectionRunning:break
  }
  
}
```


#### Set the conditions to accept the invitation
        
``` swift
mcSessionManager.onInvited { (fromPeerID, acceptAnswer) in

     acceptAnswer(true)
  
}

```        
#### Send an invitation.

``` swift
mcSesionManager.inviteTo(peerID:targetPeerID , timeout: 10)
```     

#### Request cancellation for the connected PeerID
It seems that only the target that established the direct connection is valid.
``` swift     
mcSessionManager.canselConectRequestTo(peerID: id)     
```  



### #LivePresenter#
LivePresenter is a class mainly for providing camera functions and processing of data transmission / reception.
Considering the load on the device, it is recommended to set sendVideoInterval to 0.1 or more, and set sessionPreset to low.
``` swift
do{
  self.livePresenter = try LivePresenter.init(mcSessionManager: mcSessionManager, sendVideoInterval: 0.1, sessionPreset: .low)
}catch let error{
  print(error)
}
```
 #### Processing of received data
``` swift
livePresenter.bindReceivedCallbacks(gotImage: { (image, fromPeerID) in
  // for image
}, gotAudioData: { (audioData, fromPeerID) in
  // for audio
}, gotTextMessage: {(msg, fromPeerID) in
  // for text
})
```
#### When starting the service, be sure to specify the connected MCPeerID
 ```
livePresenter.updateTargetPeerID(peerID)
 ```       
#### Send camera and microphone data
 Set true for start. Set false for stop.
 ``` swift
livePresenter.needsVideoRun = true
 ```       


#### Switch between the front camera and the rear camera
``` swift
do{
  try livePresenter.toggleCamera()
}catch let error{
  print(error)
}

```        

#### play audio
``` swift
do{
  try livePresenter.playSound(audioData: audioData)
}catch let error{
  print(error)
}
```

## Other notes

- Please turn on wifi.
- If connection is not good even after repeated connections, It may be better to stop the connection once.
- Currently, PCMSampleBuffer's audio processing doesn't go well Images are sent using the MCSession's send method and audio using the stream method. When sending text, it is also sent by the send method.
- I use [SnapKit](https://github.com/SnapKit/SnapKit) only with Demo.

## Getting started

#### Carthage
```
github "hayao11/MultipeerLiveKit"
```

#### CocoaPods
```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
 pod 'MultipeerLiveKit'
end
```

# Licence

[MIT](https://github.com/hayao11/MultipeerLiveKit/blob/master/LICENSE)

# Author

[Takashi Miyazaki](https://github.com/hayao11)
