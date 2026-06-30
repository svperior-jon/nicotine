cask "nicotine" do
  version "1.0.3"
  sha256 "d336a076e12f9ec13a6a6d56a4c6067d1a05cb6c44261a56292fce07861dc133"

  url "https://github.com/svperior-jon/nicotine/releases/download/v#{version}/Nicotine-#{version}.zip"
  name "Nicotine"
  desc "Menu bar app that keeps your Mac display awake"
  homepage "https://github.com/svperior-jon/nicotine"

  depends_on macos: :ventura

  app "Nicotine.app"

  zap trash: "~/Library/Preferences/com.jonathandecollibus.Nicotine.plist"
end
