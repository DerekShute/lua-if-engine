-- Makefile and compiled bytecode don't need require
-- require 'if-engine'

-- ======================================
-- SAMPLE GAME
-- ======================================

--
-- Messages
--
local door_is_closed = 'Walking into closed doors, are we?'

-------------------

-- TODO : basement with door, from kitchen
-- TODO : dining room

-- DOT entry -> kitchen [dir=both]
-- DOT entry -> livingroom [dir=both]
-- DOT entry -> bathroom [style=dashed dir=both]
-- DOT kitchen -> basement [style=dashed dir=both]

game_rooms = {
   {  id = 'entry', name = 'Entry',
      look = 'Inside the front door, with a bathroom door to the west, the living room to the south, and the kitchen to the east.',
      exits = {
	 west = function ( self )
	    if game.object_state('bathroomdoor') ~= 'open' then
	       return '', door_is_closed
	    else
	       return 'bathroom' -- TODO: need second return?
	    end
	 end,
	 east = 'kitchen',
	 south = 'livingroom',
      },
   },
   {  id = 'bathroom', name = 'Bath',
      look = 'As gross as it sounds.  Door to the east.',
      exits = {
	 east = function ( self )
	    if game.object_state('bathroomdoor') ~= 'open' then
	       return '', door_is_closed
	    else
	       return 'entry'
	    end
	 end,
      },
   },
   {  id = 'kitchen', name = 'Kitchen',
      depart = 'The floor is unpleasantly sticky.',
      look = 'A counter and stove, neither clean.  Hallway to the west.  An imposing basement door leads south.',
      exits = {
	 west = 'entry',
	 south = function ( self )
	    if game.object_state('basementdoor') ~= 'open' then
	       return '', door_is_closed
	    else
	       return 'basement' -- TODO: need second return?
	    end
	 end,
	 down = function ( self )
	    if game.object_state('basementdoor') ~= 'open' then
	       return '', door_is_closed
	    else
	       return 'basement' -- TODO: need second return?
	    end
	 end,
      },
   },
   {  id = 'livingroom', name = 'Living Room',
      depart = 'Is this carpet all wet?  And with what?  Eww.',
      look = 'Couch in the corner, across from the TV.  Very squalid.  Entryway to the north.',
      exits = {
	 north = 'entry',
      },
   },
   -- TODO : detail, should be dark
   {  id = 'basement', name = 'Basement',
      flags = 'dark',
      look = 'A place that should be detailed.',
      exits = {
	 up = function ( self )
	    if game.object_state('basementdoor') ~= 'open' then
	       return '', door_is_closed
	    else
	       return 'kitchen'
	    end
	 end,
      },
   },
}

game_objects = {
   {  id = 'bathroomdoor', name = 'bathroom door', alias = 'door',
      location = 'entry bathroom',
      state = 'closed', flags = 'prop',
      verbs = {
	 examine = function (self)
	    r = 'A bathroom door.  It is currently '
	    if self.state == 'closed' then
	       r = r..'closed.'
	    else
	       r = r..'open.'
	    end
	    return r
	 end,
	 open = function (self)
	    if self.state == 'closed' then
	       self.state = 'open'
	       -- TODO: locked
	       return 'It should be locked, but instead swings open.'
	    else
	       return 'Already done, chief.'
	    end
	 end,
	 close = function (self)
	    if self.state == 'open' then
	       self.state = 'closed'
	       return 'It swings shut.'
	    else
	       return 'Already done, chief.'
	    end
	 end,
      },
   },
   {  id = 'counter', name = 'counter', alias = 'counter countertop',
      location = 'kitchen',
      flags = 'prop',
      verbs = {
	 examine = 'Ugly formica that has been battered heavily.',
	 take = 'Wobbly but still attached to the wall and floor.  It\'s not going anywhere.',
	 attack = 'Thumping it accomplishes nothing.',
      },
   },
   {  id = 'stove', name = 'stove', alias = 'stove stovetop',
      location = 'kitchen',
      state = 'closed', flags = 'prop',
      verbs = {
	 examine = function (self)
	    r = 'I am not cooking anything on that.'
	    if self.state == 'closed' then
	       r = r..'  It is currently closed.'
	    else
	       r = r..'  It is currently hanging open.'
	    end
	    return r
	 end,
	 take = 'Big, heavy, and bolted to the floor.',
	 attack = 'Thumping it accomplishes nothing.',
	 open = function ( self )
	    self.state = 'open'
	    return 'It creaks open.  A decade of burnt mess lurks inside.'
	 end,
	 close = function ( self )
	    self.state = 'closed'
	    return 'It slams shut.  This is probably for the best.'
	 end,
      },
   },
   {  id = 'basementdoor', name = 'basement door', alias = 'door',
      location = 'kitchen',
      state = 'closed', flags = 'prop',
      verbs = {
	 examine = function (self)
	    r = 'A door, currently '
	    if self.state == 'closed' then
	       r = r..'closed.'
	    else
	       r = r..'open.'
	    end
	    return r
	 end,
	 open = function (self)
	    if self.state == 'closed' then
	       self.state = 'open'
	       return '*Creeeeak* This looks promising.'
	    else
	       return 'Already done, chief.'
	    end
	 end,
	 close = function (self)
	    if self.state == 'open' then
	       self.state = 'closed'
	       return '*Creeeeak WHAM*'
	    else
	       return 'Already done, chief.'
	    end
	 end,
      },
   },

   {  id = 'couch', name = 'couch', alias = 'couch sofa',
      location = 'livingroom',
      flags = 'prop',
      verbs = {
	 examine = 'Unidentified stains, small tears, lumps.  Delightful!',
	 take = 'You\'d need a second person.',
	 attack = 'Take that, inanimate object!  It is unrepentant.',
      },
   },
   {  id = 'television', name = 'television', alias = 'tv television',
      location = 'livingroom',
      state = 'off', flags = 'prop',
      -- TODO: is a prop, and implements look.  Only output if the TV is on?  Alter room look output for an on TV?
      look = function (self)
	 r = 'Squatting against a wall is a big, old television'
	 if self.state == 'on' then
	    r = r..' showing some black-and-white program.'
	 else
	    r = r..'.'
	 end
	 return r
      end,
      verbs = {
	 examine = function (self)
	    r = 'A dusty wood-grained box with big glass front.'
	    if self.state == 'on' then
	       r = r..'  It is currently showing some black-and-white program.'
	    end
	    return r
	 end,
	 take = 'This thing is not going anywhere.',
	 attack = 'Take that, inanimate object!  It is unrepentant.',
	 turnon = function ( self )
	    self.state = 'on'
	    return 'A click and a warm hum and it dimly starts playing Howdy Doody.  Is that even still a show?'
	 end,
	 turnoff = function ( self )
	    self.state = 'off'
	    return 'A click and the image shrinks to a pinprick and gone.'
	 end,
      },
   },
   {  id = 'flashlight', name = 'rusty flashlight', alias = 'light flashlight torch',
      location = 'kitchen',
      look = function ( self )
	 -- TODO: better interface?
	 if game.is_flag_set(self.id, 'initial') then
	    return 'A rusty flashlight sits on the counter.'
	 else
	    r = 'There is a rusty flashlight here.'
	    if game.is_flag_set(self.id, 'lit') then
	       r = r..'  It is feebly shining.'
	    end
	    return r
	 end
      end,
      verbs = {
	 examine = function ( self )
	    r = 'You have serious doubts about its ability to emit light.'
	    if game.is_flag_set(self.id, 'lit') then
	       r = r..'  Yet it appears to be doing so.'
	    end
	    return r
	 end,
	 -- TODO: timer for flashlight use
	 turnon = function ( self )
	    return game.set_light (self, true,
				   'It reluctantly flickers to life.  Better get this done quickly.',
				   'Already done, chief.');
	 end,
	 turnoff = function ( self )
	    return game.set_light (self, false,
				   'Turning it off was easier than turning it on.',
				   'Already off, chief.');
	 end,
	 take = game.simple_take,
	 drop = game.simple_drop,
	 attack = 'No thanks.',
      },
   },
}

--============================================
-- Game Start and Run
--============================================

game.name = 'Derek\'s First Attempt At A Game'
game.version = 'Pathetic'
game.initial_room = 'entry'
-- Override game verbs
game.verbs.help = 'Figure it out your darn self.'

game.go()

-- EOF
