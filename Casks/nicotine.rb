cask "nicotine" do
  version "1.0.0"
  sha256 "efb259085ab0a04fca289fd82be37b8faa170fb8f0f42b93ba51900906d4adde"

  url "https://github.com/svperior-jon/nicotine/releases/download/v#{version}/Nicotine-#{version}.zip"
  name "Nicotine"
  desc "Menu bar app that keeps your Mac display awake"
  homepage "https://github.com/svperior-jon/nicotine"

  depends_on macos: :ventura

  app "Nicotine.app"

  zap trash: "~/Library/Preferences/com.jonathandecollibus.Nicotine.plist"
end
