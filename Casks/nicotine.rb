cask "nicotine" do
  version "1.0.1"
  sha256 "fd8b32cac25af2b0a157c037ac4831a2a94b9311f08df74095cf080f299b68af"

  url "https://github.com/svperior-jon/nicotine/releases/download/v#{version}/Nicotine-#{version}.zip"
  name "Nicotine"
  desc "Menu bar app that keeps your Mac display awake"
  homepage "https://github.com/svperior-jon/nicotine"

  depends_on macos: :ventura

  app "Nicotine.app"

  zap trash: "~/Library/Preferences/com.jonathandecollibus.Nicotine.plist"
end
