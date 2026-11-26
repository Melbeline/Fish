# Easy Fishing

A small fishing addon for WoW Forever (the game's own UI first; it uses only the game's menus and options).
Since 2.0, its fishing code is **Clara Combo Points'** own: `Fishing.lua` and `FishingMode.lua` are the files of
Clara's Fishing module, as they are, updated with Clara. The rest (its options page, its portrait menu entry, its
key button) is Easy Fishing's own.

**FR** — Un addon de pêche pour WoW Forever. Depuis la 2.0, son code de pêche est celui de **Clara Combo Points** :
`Fishing.lua` et `FishingMode.lua` sont les fichiers du module Pêche de Clara, tels quels, mis à jour avec Clara.

- **Une touche pour pêcher et ferrer** (Échap > Options > Raccourcis > Easy Fishing : *Pêcher / Ferrer* ; la touche
  choisie en 1.x reste la même).
  - Appuyer une fois lance la ligne.
  - Pendant que la ligne est lancée, la même touche ferre le bouchon (la touche d'interaction du jeu) : une touche, une action.
  - Sans canne en main, le premier appui équipe celle des sacs. Les armes reviennent quand le mode pêche est désactivé.
- **Mode pêche** (celui de Clara) : coupe la musique, l'ambiance et les voix, la réverbération et le filtrage de
  distance, met les effets sonores à 100 % (le plouf du bouchon en fait partie), monte le **volume général** (×2 par
  défaut, jusqu'à ×10, jamais plus de 100 %) et garde le son quand le jeu est en arrière-plan. Tout est remis comme
  avant en le désactivant, et à chaque déconnexion (remis à la connexion suivante). Il s'active :
  - par le **clic droit sur le portrait**, section *Pêche*, en bas du menu (hors combat : le jeu y refuse les entrées
    des addons en combat) ;
  - par une case sur la **carte Pêche** de la fenêtre des métiers (onglet Professions) ;
  - par sa page d'options.
- **Options** : Échap > Options > AddOns > Easy Fishing, ou `/easyfishing` (`/ef`) : le mode, le volume général en mode
  pêche (×1 à ×10), et deux boutons : choisir la touche *Pêcher / Ferrer* (clic, puis la touche ou le bouton de souris
  voulu, avec Maj, Ctrl ou Alt si besoin ; Échap annule) et la supprimer.
- `/rl` recharge l'interface (comme `/reload`).
- **Depuis la 1.x** : les réglages sont repris (le mode, les armes qu'une canne a remplacées, les sons que l'ancien
  mode avait coupés, rendus comme avant). Le haut-parleur et le curseur des effets sonores du menu du portrait n'existent
  plus (le volume se règle avec le jeu, Ctrl+S coupe tout).
- **Avec Clara Combo Points** : tant qu'Easy Fishing est activé, c'est lui qui tourne, et le module Pêche de Clara se met
  en retrait (le même code, ses réglages à part).

**EN**
- **One key to fish and reel in** (Esc > Options > Keybindings > Easy Fishing: *Fish / Reel in*; the key bound in 1.x is kept).
- **Fishing mode** (Clara's): music, ambience and voices off, reverb and distance filtering too, sound effects at 100 %,
  the **master volume** louder (×2 by default, up to ×10, never past 100 %), sound kept in the background. All given
  back when it is turned off. From the portrait's menu (out of combat), the Fishing card of the professions window,
  and its options page.
- **Options**: Esc > Options > AddOns > Easy Fishing, or `/easyfishing` (`/ef`): the mode, the master volume in fishing
  mode, and two buttons to set and remove the *Fish / Reel in* key. `/rl` reloads the interface.
- From 1.x: its settings are carried over; the portrait menu's speaker and sound effects slider are gone.
- With Clara Combo Points: while Easy Fishing is enabled, it runs, and Clara's Fishing module stands aside.

Install: copy the `EasyFishing` folder into `World of Warcraft/_forever_/Interface/AddOns/`.

## 2.0.1

- **Community fixes** (the same as Clara Combo Points', one copy running at a time): a community chat the game failed to join at the login joined again; the Guild & Communities window shows who is online in a community (the game's window never asked for its members' presence). Appear Offline on Battle.net still hides a player from the communities: the player's choice.

- **Correctifs des communautés** (les mêmes que ceux de Clara Combo Points, une seule copie tourne à la fois) : un chat de communauté que le jeu n'a pas rejoint à la connexion est rejoint à nouveau ; la fenêtre Guilde & Communautés montre qui est en ligne dans une communauté (la fenêtre du jeu ne demandait jamais la présence de ses membres). « Apparaître hors ligne » sur Battle.net cache toujours un joueur des communautés : c'est son choix.
