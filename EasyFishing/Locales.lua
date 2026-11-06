-- Easy Fishing - texts (English, then French and German)
local _, ns = ...

local L = {
  TITLE = "Easy Fishing",
  FISHING = "Fishing",
  MODE = "Fishing mode",
  MODE_TIP = "Music, ambience and voices off, reverb and distance filtering too, sound effects at %d %%, master volume ×%d, sound kept while the game is in the background: the splash heard over the rest. All given back when it is turned off.",
  BINDING = "Fish / Reel in (one press, one action)",
  MUTE = "Mute all sounds",
  UNMUTE = "Sound back on",
  SFX = "Sound effects volume",
  BOOST = "Master volume in fishing mode",
  BOOST_TIP = "The master volume multiplied while fishing mode is on, never past 100 %.",
}

local locale = GetLocale and GetLocale()
if locale == "frFR" then
  L.FISHING = "Pêche"
  L.MODE = "Mode pêche"
  L.MODE_TIP = "Musique, ambiance et voix coupées, réverbération et filtrage de distance aussi, effets sonores à %d %%, volume général ×%d, son gardé quand le jeu est en arrière-plan : le plouf s'entend par-dessus le reste. Tout est remis comme avant en le désactivant."
  L.BINDING = "Pêcher / Ferrer (une touche, une action)"
  L.MUTE = "Couper tous les sons"
  L.UNMUTE = "Remettre le son"
  L.SFX = "Volume des effets sonores"
  L.BOOST = "Volume général en mode pêche"
  L.BOOST_TIP = "Le volume général multiplié tant que le mode pêche est actif, jamais plus de 100 %."
elseif locale == "deDE" then
  L.FISHING = "Angeln"
  L.MODE = "Angelmodus"
  L.MODE_TIP = "Musik, Umgebung und Stimmen aus, ebenso Hall und Entfernungsfilter, Soundeffekte auf %d %%, Gesamtlautstärke ×%d, Ton bleibt an, wenn das Spiel im Hintergrund ist: das Platschen hört man über allem. Beim Ausschalten wird alles zurückgesetzt."
  L.BINDING = "Angeln / Einholen (ein Druck, eine Aktion)"
  L.MUTE = "Alle Töne aus"
  L.UNMUTE = "Ton wieder an"
  L.SFX = "Lautstärke der Soundeffekte"
  L.BOOST = "Gesamtlautstärke im Angelmodus"
  L.BOOST_TIP = "Die Gesamtlautstärke, vervielfacht solange der Angelmodus an ist, nie über 100 %."
end

ns.L = L
BINDING_HEADER_EASYFISHING = L.TITLE
_G["BINDING_NAME_CLICK EasyFishingButton:LeftButton"] = L.BINDING
