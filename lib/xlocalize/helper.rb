
module Xlocalize
  
  class Helper

    def self.xcode_version
      output = `xcodebuild -version`
      output.split("\n").first.split(' ')[1]
    end

    def self.xcode_at_least?(version)
      v = xcode_version
      Gem::Version.new(v) >= Gem::Version.new(version)
    end
  end
end
