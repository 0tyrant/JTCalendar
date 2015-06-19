Pod::Spec.new do |s|
  s.name         = "JTCalendar"
  s.version      = "1.2.3"
  s.summary      = "A customizable calendar view for iOS."
  s.homepage     = "https://github.com/0tyrant/JTCalendar"
  s.license      = { :type => 'MIT' }
  s.author       = { "Jonathan Tribouharet" => "jonathan.tribouharet@gmail.com" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/0tyrant/JTCalendar.git", :commit => "d5b4ded595aa134bbda899421ac2ae9e2dc72f7f" }
  s.source_files  = 'JTCalendar/*'
  s.requires_arc = true
  s.screenshots   = ["https://raw.githubusercontent.com/jonathantribouharet/JTCalendar/master/Screens/example.gif"]
end
