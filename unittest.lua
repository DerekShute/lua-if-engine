game_rooms = {
   -- Test1: Just an empty room
   {  id = 'test0', name = 'Test0 Empty Room',
      look = 'look callback, test0: empty room',
      exits = {
	 west = 'test1',
      },
   },

   -- Test1 contains thing1 and thing2 and prop1
   --  and reports object state of thing1, just to exercise the code
   {  id = 'test1', name = 'Test1 Title',
      depart = 'Departing test1',
      look =  function ( self )
	 x = 'look callback (function), test1.  Prop1 should not be a shown object'
	 if game.is_flag_set('thing2', 'initial') then
	    x = x..' (Thing2 still INITIAL)'
	 else
	    x = x..' (Thing2 not INITIAL)'
	 end
	 x = x..' Thing1 state is \''..game.object_state('thing1')..'\'.'
	 return x
      end,
      exits = {
	 west = 'test2',
	 east = 'test0',
      },
   },
   -- Test2 contains everywhere1
   {  id = 'test2', name = 'Test2 Title',
      depart = 'Departing test2',
      look = 'look callback, test2',
      exits = {
	 west = 'test3',
	 east = 'test1',
      },
   },
   -- Test3 contains everywhere1.  This is a dark place.
   {  id = 'test3', name = 'Test3 Title',
      flags = 'dark',
      look = 'look callback, test3',
      exits = {
	 east = 'test2',
      },
   },
}

game_objects = {
   {  id = 'thing1', name = 'first thing', alias = 'thing1 t1',
      location = 'test1',
      state = 'thing1state',
      look = 'Thing1 implements look method.',
      verbs = {
	 examine = 'Examining thing1',
	 take = 'Failing to take thing1.',
      },
   },
   {  id = 'thing2', name = 'second thing', alias = 'thing2 t2',
      location = 'test1',
      verbs = {
	 examine = 'Examining thing2.',
	 take = game.simple_take,
	 drop = game.simple_drop,
      },
   },
   {  id = 'thing3', name = 'third thing', alias = 'thing3 t3',
      location = 'test2',
      verbs = {
	 examine = 'Examining thing3.',
	 take = game.simple_take,
	 drop = game.simple_drop,
      },
   },
   -- Prop1 and prop2 have the same alias.  Can the engine tell them apart
   -- based on current room?
   {  id = 'prop1', name = 'first prop', alias = 'prop p1',
      location = 'test1',
      flags = 'prop',
      verbs = {
	 examine = 'Examining prop1 in test1, as prop.',
	 take = 'Failing to take prop1 called prop.',
      },
   },
   {  id = 'prop2', name = 'second prop', alias = 'prop',
      location = 'test2', flags = 'prop',
      verbs = {
	 examine = 'Examining prop2 in test2, as prop.',
	 take = 'Failing to take prop2 called prop.',
      },
   },
   {  id = 'lantern', name = 'lantern', alias = 'lantern',
      location = 'test2',
      verbs = {
	 examine = 'Examining lantern.',
	 take = game.simple_take,
	 drop = game.simple_drop,
         turnon = function ( self )
            return game.set_light (self, true,
                                   'Turns on.', 'Already on.');
         end,
         turnoff = function ( self )
            return game.set_light (self, false,
                                   'Turns off.', 'Already off.');
         end,
      },
   },
   -- The only point is for this to be visible in multiple places
   {  id = 'everywhere1', name = 'first everywhere', alias = 'everywhere',
      location = 'test2 test3',
      look = 'everywhere1 in rooms test2 and test3 (look)',
      verbs = {},
   },
}

--============================================
-- Game Start and Run
--============================================

game.name = 'Unit Test World'
game.version = '1.0'
game.initial_room = 'test0'
-- Override game verbs
game.verbs.help = 'Help message provided by unittest.'

game.go()

-- EOF
