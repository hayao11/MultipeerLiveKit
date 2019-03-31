
Pod::Spec.new do |s|

  s.name         = "MultipeerLiveKit"
  s.version      = "1.0.1"
  s.summary      = "Multipeer Connectivity Wrapper."
  s.description  = <<-DESC
    - This library provides Live Camera and Text Chat.
    DESC

  s.homepage     = "https://github.com/hayao11/MultipeerLiveKit.git"

  s.license      = "MIT"

  s.author       = { "Takashi Miyazaki" => "hayao1900@gmail.com" }
  s.source       = { :git => "https://github.com/hayao11/MultipeerLiveKit.git", :tag => s.version }
  s.requires_arc = true
  s.platform     = :ios, '10.0'
  s.swift_version = "4.2"
  s.source_files  = "MultipeerLiveKit/**/*.swift"
end


