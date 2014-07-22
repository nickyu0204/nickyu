Pod::Spec.new do |s|
  s.name         = "ZDDataManager"
  s.version      = "1.0.0"
  s.summary      = "知道ios端,数据操作处理器"

  s.description  = <<-DESC
                    数据处理器 支持sqlite,plist 增删改查
                   DESC

  s.homepage     = "http://EXAMPLE/ZDDataManager"
  s.author       = { "百度知道ios客户端" => "俞鑫" }
  s.platform     = :ios
  s.ios.deployment_target = '5.0'
  s.source_files  = 'ZDDataManager/*.{h,m}'
  
  s.dependency 'FMDB','2.1'

end
