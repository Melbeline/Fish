-- Easy Fishing - texts (English, then French and German). FISH_BINDING, MENU_FISHING_MODE and FISHING_MODE_TIP are
-- Clara Combo Points' own (Fishing.lua and FishingMode.lua, shared with it as they are, read them).
local _, ns = ...

local L = {
  TITLE = "Easy Fishing",
  FISHING = "Fishing",
  FISH_BINDING = "Fish / Reel in (one press, one action)",
  MENU_FISHING_MODE = "Fishing mode",
  FISHING_MODE_TIP = "Music, ambience and voices off, reverb and distance filtering too, sound effects at 100 %% (the bobber's splash is one of them), master volume ×%d (never past 100 %%), sound kept while the game is in the background: the splash heard over the rest. All given back when it is turned off.",
  BOOST = "Master volume in fishing mode",
  KEY = "Fish / Reel in key",
  KEY_TIP = "Click, then press the key or mouse button that fishes and reels in. Esc cancels.",
  NOT_BOUND = "Not bound",
  PRESS = "Press a key...",
  CAPTURE = "Press a key or a mouse button\nEsc: cancel",
  KEY_SET = "Fish / Reel in key: %s",
  KEY_WAS = "%s was bound to \"%s\".",
  NO_CLICK = "Left and right click can't be bound.",
  COMBAT = "Key bindings can't be changed in combat.",
  KEY_CLEAR = "Remove the key",
  KEY_CLEAR_BTN = "Unbind",
  KEY_CLEAR_TIP = "Removes the Fish / Reel in key: nothing is bound until you set one again.",
  KEY_REMOVED = "Fish / Reel in key removed (%s).",
  KEY_NONE = "No Fish / Reel in key is set.",
}

local locale = GetLocale and GetLocale()
if locale == "frFR" then
  L.FISHING = "Pêche"
  L.KEY = "Touche Pêcher / Ferrer"
  L.KEY_TIP = "Cliquez, puis appuyez sur la touche ou le bouton de souris qui pêche et ferre. Échap annule."
  L.NOT_BOUND = "Non assigné"
  L.PRESS = "Appuyez sur une touche..."
  L.CAPTURE = "Appuyez sur une touche ou un bouton de souris\nÉchap : annuler"
  L.KEY_SET = "Touche Pêcher / Ferrer : %s"
  L.KEY_WAS = "%s était assignée à « %s »."
  L.NO_CLICK = "Les clics gauche et droit ne peuvent pas être assignés."
  L.COMBAT = "Impossible de changer les raccourcis en combat."
  L.KEY_CLEAR = "Supprimer la touche"
  L.KEY_CLEAR_BTN = "Supprimer"
  L.KEY_CLEAR_TIP = "Retire la touche Pêcher / Ferrer : plus rien n'est assigné tant que vous n'en choisissez pas une."
  L.KEY_REMOVED = "Touche Pêcher / Ferrer supprimée (%s)."
  L.KEY_NONE = "Aucune touche Pêcher / Ferrer n'est assignée."
  L.FISH_BINDING = "Pêcher / Ferrer (une touche, une action)"
  L.MENU_FISHING_MODE = "Mode pêche"
  L.FISHING_MODE_TIP = "Musique, ambiance et voix coupées, réverbération et filtrage de distance aussi, effets sonores à 100 %% (le plouf du bouchon en fait partie), volume général ×%d (jamais plus de 100 %%), son gardé quand le jeu est en arrière-plan : le plouf s'entend par-dessus le reste. Tout est remis comme avant en le désactivant."
  L.BOOST = "Volume général en mode pêche"
elseif locale == "deDE" then
  L.FISHING = "Angeln"
  L.KEY = "Taste Angeln / Einholen"
  L.KEY_TIP = "Klicken, dann die Taste oder Maustaste drücken, die angelt und einholt. Esc bricht ab."
  L.NOT_BOUND = "Nicht belegt"
  L.PRESS = "Taste drücken ..."
  L.CAPTURE = "Taste oder Maustaste drücken\nEsc: abbrechen"
  L.KEY_SET = "Taste Angeln / Einholen: %s"
  L.KEY_WAS = "%s war mit \"%s\" belegt."
  L.NO_CLICK = "Linke und rechte Maustaste können nicht belegt werden."
  L.COMBAT = "Tastenbelegung im Kampf nicht änderbar."
  L.KEY_CLEAR = "Taste entfernen"
  L.KEY_CLEAR_BTN = "Entfernen"
  L.KEY_CLEAR_TIP = "Entfernt die Taste für Angeln / Einholen: nichts ist belegt, bis du eine neue festlegst."
  L.KEY_REMOVED = "Taste Angeln / Einholen entfernt (%s)."
  L.KEY_NONE = "Keine Taste für Angeln / Einholen belegt."
  L.FISH_BINDING = "Angeln / Einholen (ein Tastendruck, eine Aktion)"
  L.MENU_FISHING_MODE = "Angelmodus"
  L.FISHING_MODE_TIP = "Musik, Umgebung und Stimmen aus, Hall und Distanzfilter auch, Soundeffekte auf 100 %% (das Platschen des Schwimmers gehört dazu), Gesamtlautstärke ×%d (nie über 100 %%), Ton auch bei Spiel im Hintergrund: das Platschen ist über allem zu hören. Beim Ausschalten wird alles zurückgesetzt."
  L.BOOST = "Gesamtlautstärke im Angelmodus"
end

ns.L = L
BINDING_HEADER_EASYFISHING = L.TITLE
