Pod::Spec.new do |s|
  s.name             = 'native_sqlite_ios'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation of native_sqlite'
  s.description      = <<-DESC
  iOS implementation of native_sqlite - A SQLite plugin accessible from both native and Flutter code.
                       DESC
  s.homepage         = 'https://nesmin.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nesmin' => 'dev@nesmin.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.library = 'sqlite3'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
