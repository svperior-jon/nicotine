cask "nicotine" do
  version "1.0.0"
  sha256 "db1e769a17f0ac5003c99a08d1194316b96f5bc68635af8798dcfccdd74460d1"

  url "https://github.com/svperior-jon/nicotine/releases/download/v#{version}/Nicotine-#{version}.zip"
  name "Nicotine"
  desc "Menu bar app that keeps your Mac display awake"
  homepage "https://github.com/svperior-jon/nicotine"

  depends_on macos: :ventura

  app "Nicotine.app"

  zap trash: "~/Library/Preferences/com.jonathandecollibus.Nicotine.plist"
end
