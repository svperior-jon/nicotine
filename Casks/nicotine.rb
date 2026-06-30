cask "nicotine" do
  version "1.0.2"
  sha256 "fc025190fa100bc70a8542bc07b1af2c5c4af257eb502003ecc22bd31df9ba41"

  url "https://github.com/svperior-jon/nicotine/releases/download/v#{version}/Nicotine-#{version}.zip"
  name "Nicotine"
  desc "Menu bar app that keeps your Mac display awake"
  homepage "https://github.com/svperior-jon/nicotine"

  depends_on macos: :ventura

  app "Nicotine.app"

  zap trash: "~/Library/Preferences/com.jonathandecollibus.Nicotine.plist"
end
