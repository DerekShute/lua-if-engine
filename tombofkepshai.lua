-- Makefile and compiled bytecode don't need require
-- require 'if-engine'

-- ======================================
-- Not the Island of Kesmai, 
--    or the Tomb of Setmoth,
--       or the Temple of Apshai
--
-- This is:
--
--          THE TOMB OF KEPSHAI
--
-- ======================================

-- TODO: room diagrams
-- TODO: unit test, canonical solution

-- TODO: torches stuck into ground, can take
game_rooms = {
   {  id = 'entry', name = 'At The Skull Mouth',
      look = 'You are at the entrance of the fabled Tomb of Kepshai.  Some enterprising soul has painstakingly carved it into an enormous skull face.  To enter you must walk south through its gaping, toothy maw.',
      -- TODO: only first time
      depart = 'The flickering lights in its eyes seem to follow you as you approach and descend.',
      exits = {
	 south = 'tunnel',
	 down = 'tunnel',
      },
   },
   {  id = 'tunnel', name = 'Dank Tunnel',
      look = 'Outside light quickly fades as you travel down the gullet of the skull face.',
      exits = {
	 south = 'tunnel',
      },
   },
}

game_objects = {
   {  id = 'face', name = 'skull face', alias = 'skull face',
      location = 'entry',
      flags = 'prop',
      verbs = {
	 examine = function (self)
	    -- TODO: unhide small item (a torch, causing socket to flicker?)
	    -- TODO: climb?  Stick?
	    return 'You find a small item hidden in an eye socket.'
	 end
      },
   },
}
--============================================
-- Game Start and Run
--============================================

game.name = 'Tomb of Kepshai'
game.version = '0.1'
game.initial_room = 'entry'

game.go()

-- EOF
