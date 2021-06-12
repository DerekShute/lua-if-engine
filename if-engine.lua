-- See https://gist.github.com/randrews/994437
-- See http://www.playwithlua.com/?p=20
-- See http://www.playwithlua.com/?p=22
-- https://github.com/randrews/lua-if
-- Style guide start here
--      https://github.com/Olivine-Labs/lua-style-guide

--========================================
-- SUPER USEFUL STUFF
--========================================
local function evaluate(x, ...)
   if type(x) == 'function' then
      return x(...) -- I don't know why this works
   else
      return x
   end
end

-- TODO: must manage word wrap given terminal column count.
local function tell(...)
   return io.write(...)
end

local function error(...)
   -- TODO: set off with asterisks
   -- TODO: terminate program?
   return tell(...)
end

-- =====================
-- Flag field as a string.  Set, clear, and test.  Arbitrary flag names
--
local function is_flag_set(flags, name)
   return string.find(flags, ' '..name..' ') ~= nil
end

local function set_flag(flags, name)
   if is_flag_set(flags, name) == false then
      return flags..' '..name..' '
   else
      return flags
   end
end

local function clear_flag(flags, name)
   if is_flag_set(flags, name) then
      return string.gsub(flags, ' '..name..' ', '')
   else
      return flags
   end
end

-- Initializer.  Takes list of words and formats for flags
local function set_all_flags(namelist)
   r = ''
   if namelist == nil then
      return r
   end
   for v in string.gmatch(namelist, "[^%s]+") do
      r = r..' '..v..' '
   end
   return r
end

-- =====================

local function introduction ()
   tell('Starting ', game.name, '\n')
   tell('Version ',game.version, '\n')
   tell('\n')
end

local function remove_object(o, from_loc)
   if is_flag_set(o.location, from_loc) then
      rooms[from_loc].contents = clear_flag(rooms[from_loc].contents, o.id)
      o.location = clear_flag(o.location, from_loc)
      o.flags = clear_flag(o.flags, 'initial')
      return 1
   else
      return 0
   end
end

local function put_object(o, to_loc)
   o.location = set_flag(o.location, to_loc)
   o.flags = clear_flag(o.flags, 'initial')
   rooms[to_loc].contents = set_flag(rooms[to_loc].contents, o.id)
end

-- Print prompt, accept input.  unparsed as l.raw, atoms as l[x]
local function get_line ()
   local l = {}
   local i = 1

   tell(game.prompt)
   l.raw = string.lower(io.read())
   -- TODO: will this 'while' or 'ipair'?  Auto-increment
   for v in string.gmatch(l.raw, "[^%s]+") do
      l[i] = v
      i = i + 1
   end
   return l
end

--========================================
-- DICTIONARY / LEXICON
-- =======================================
lexicon = {
   directions = {},
   verbs = {},
   objects = {},
}

-- TODO: verb-requires-object transitive-verb intransitive-verb
-- TODO: is-object
-- TODO: drop-this-word
-- TODO: next-word-is-indirect-object
-- TODO: is-subject

function lexicon.add_direction(alias, real_word)
   lexicon.directions[alias] = real_word
end

function lexicon.add_verb(alias, real_word)
   lexicon.verbs[alias] = real_word
end

-- For each t.verbs[key], add to the lexicon
function lexicon.add_verbs(t)
   local key
   local value

   if t.verbs == nil then
      return
   end

   -- TODO: if t.verbs[x] is a string, verb aliases to that value
   for key,value in pairs(t.verbs) do
      if lexicon.verbs[key] == nil then
         lexicon.verbs[key] = key
      end
   end
end

--
-- Add direction words that we don't already know about
--
function lexicon.add_directions(room)
   local key, value

   if room.exits == nil then -- Kind of a shady concept
      return
   end

   for key,value in pairs(room.exits) do
      if lexicon.directions[key] == nil then
         lexicon.directions[key] = key
      end
   end
end

-- IN PROGRESS: not this thing's job to convert aliases to object names
function lexicon.add_object(alias, real_word)
   if lexicon.objects[alias] == nil then
      lexicon.objects[alias] = ''
   end

   lexicon.objects[alias] = set_flag(lexicon.objects[alias], real_word)
end


-- ======================================
-- GAME INTRINSICS
--     game.name : string, output at game start
--     game.version : string, output at game start
--     game.initial_room : room name
--     game.current_room : room name
--
--     game.add_objects : list of object structures
--     game.add_rooms : list of room structures
--     game.go : commence the input/parse/evaluate cycle
--     game.goto_room : set current room
--     game.set_light : turn on or off a light
--     game.inventory : player inventory, as a flag list
--     game.is_flag_set : object (by name) has a flag set (returns boolean)
--     game.set_flag: set the object (by name) flag
--     game.clear_flag: clear the object (by name) flag
--     game.object_state : object (by name) state string
--     game.prompt : at command input.  String, generally.
--     game.running : boolean.  false -> end the game
--     game.simple_take
--     game.simple_drop
--     game.verbs
--               .go : Travel in a direction.
--               .help : string or other.  For 'help' command.
--               .inventory : method, encapsulates 'inventory' command.
--               .look : method, encapsulates 'look' function
--               .quit : end the game
-- ======================================
-- TODO: serialization and deserialization

game = {
   name = 'Some unnamed game',
   version = 'Some TBD version',
   running = 1,
   prompt = '>',
   current_room = '',
   verbs = {
      help = 'Some help message would be helpful.',
   },
   inventory = '',  -- As a flag field: use set/clear flags interface
   is_dark = false,
}

local function is_verb_implemented (x, verb)
   return x and x.verbs and x.verbs[verb]
end

local function dispatch (x, verb, line)
   return evaluate(x.verbs[verb], x, line)
end

local function calculate_dark (room)
   -- Implied that room is current room, else game.is_dark is meaningless
   game.is_dark = false
   if is_flag_set(room.flags, 'dark') then
      game.is_dark = true
      -- TODO: concatenate list of objects
      for o in string.gmatch(game.inventory, "[^%s]+") do
         if is_flag_set(objects.store[o].flags, 'lit') then
            game.is_dark = false
            break
         end
      end
      if game.is_dark then
         for o in string.gmatch(room.contents, "[^%s]+") do
            if is_flag_set(objects.store[o].flags, 'lit') then
               game.is_dark = false
               break
            end
         end
      end
   end
end

function game.goto_room (x)
   local output
   local r

   -- TODO: how does darkness deal with all this?
   if game.current_room ~= '' then
      r = rooms[game.current_room]
      if r.depart then
	 tell(evaluate(r.depart, game.current_room)..'\n')
	 tell('\n')
      end
      if rooms[x].enter then
	 tell(evaluate(room[x].enter, x)..'\n')
	 tell('\n')
      end
   end

   game.current_room = x
   r = rooms[game.current_room]
   calculate_dark(r)

   -- TODO: terse and verbose
   if is_flag_set(r.flags, 'first_enter') then
      p = rooms.look_output(game.current_room)
   else
      if game.is_dark then
	 p = 'You are in a dark place.'
      else
	 p = r.name
      end
   end
   r.flags = clear_flag(r.flags, 'first_enter')
   return p
end

-- Main Game Action Loop =========== 
--    Get line, parse, dispatch, repeat.
--    Return value is a string with result (no newline, but period terminates)
-- TODO: for player 'actor'

local function take_action ()
   local possible_objects = ''
   local line = get_line()
      -- line.raw, line.subject, line.verb, line.specifier, line.object, 
      -- line.indirect

   -- START PARSING
   -- TODO: to 'parse' method

   -- STEP 0: Must recognize all words
   -- TODO

   -- TODO: subject

   -- STEP 1: first word is verb
   -- TODO: 'turn off' -> 'turnoff', or verb is 'turn' and verb qualifier

   if line[1] == nil then  -- Empty line: do something witty
      return 'Beg pardon?'
   elseif lexicon.directions[line[1]] ~= nil then
      line[2] = lexicon.directions[line[1]]
      line[1] = 'go'
   elseif lexicon.verbs[line[1]] == nil then
      return 'I don\'t know the verb \''.. line[1] .. '\''
   end
   line.verb = lexicon.verbs[line[1]] -- Canonicalize

   -- TODO: is dispatch of last resort
   if is_verb_implemented(game, line.verb) then
      return dispatch(game, line.verb, line)
   end

   -- TODO: seek object, skip ignore words, etc.

   if line[2] and lexicon.objects[line[2]] == nil then
      return 'I don\'t know the word \''..line[2]..'\'.'
   end

   -- From the command line, take word 2 and construct a list of possible
   -- objects given inventory and list of objects in this room

   line.object = ''
   if lexicon.objects[line[2]] then
      for v in string.gmatch(lexicon.objects[line[2]], "[^%s]+") do
	 o = objects.store[v]
	 -- TODO: hidden objects should not be considered
	 if is_flag_set(game.inventory, v) or is_flag_set(o.location, game.current_room) then
	    line.object = set_flag(line.object, v)
	 end
      end

      -- We know the word, but no object applies
      if line.object == '' then
	 return 'There is no \''..line[2]..'\' here.'
      end

      -- Turn the object from a flag value into a single word

      line.object = string.gsub(line.object, "%s+", "")
      -- more than one name possible : Ambiguous
      -- TODO: Probably a better way to handle this
      if objects.store[line.object] == nil then
	 return 'I don\'t know which object you are referring to.'
      end
      o = objects.store[line.object]
      if is_verb_implemented(o, line.verb) then
	 return dispatch(o, line.verb, line)
      end
   end

   if is_verb_implemented(rooms[game.current_room], line.verb) then
      return dispatch(rooms[game.current_room], line.verb, line)
   end

   -- TODO : what next?
   return 'No way to do that here and now.'
end

-- MAIN GAME ENTRYPOINT
function game.go ()
   game.add_rooms(game_rooms)
   game.add_objects(game_objects)

   -- Start the interesting stuff
   introduction()

   -- Prints initial look, sets initial room
   -- TODO: need default initial room if not set
   tell(game.goto_room(game.initial_room)..'\n\n')

   -- Main Loop : repeat until no more game
   repeat
      -- Extra newline to skip space after game output and before prompt
      tell(take_action(),'\n\n')

      -- TODO : determine light sources?
   until game.running == 0

end

-- NOTE: Specific to objects.  Returns BOOLEAN
function game.is_flag_set(object_name, flagname)
   return is_flag_set(objects.store[object_name].flags, flagname)
end

function game.set_flag(object_name, flagname)
   o = objects.store[object_name]
   o.flags = set_flag(o.flags, flagname)
end

function game.clear_flag(object_name, flagname)
   o = objects.store[object_name]
   o.flags = clear_flag(o.flags, flagname)
end

-- TODO: can't take anything if it's dark
function game.simple_take(self)
   if is_flag_set(game.inventory, self.id) then
      return 'You are already holding the '..self.name..'.'
   end
   if is_flag_set(self.location, game.current_room) == false then
      print ("simple_take: self.location is ", self.location)
      return 'There is no \''..self.name..'\' here.'
   end
   remove_object(self, game.current_room)
   -- TODO: can't be in any other location
   self.location = set_flag('','_inventory')
   game.inventory = set_flag(game.inventory, self.id)
   return 'You take the '..self.name..'.'
end

function game.simple_drop(self)
   if is_flag_set(game.inventory, self.id) == false then
      return 'You do not have the '..self.name..'.'
   end
   put_object(self, game.current_room)
   game.inventory = clear_flag(game.inventory, self.id)
   return 'You drop the '..self.name..'.'
end

function game.object_state(object_name)
   -- TODO: guard against nil object?
   o = objects.store[object_name]
   if o.state ~= nil then
      return o.state
   else
      return ''
   end
end

function game.set_light(o, lit, success, failure)
   r = ''
   -- TODO: if success or failure are empty strings, provide defaults

   if lit == is_flag_set(o.flags, 'lit') then
      return evaluate(failure, o, lit)
   end

   r = evaluate(success, o, lit)
   if lit then
      o.flags = set_flag(o.flags, 'lit')
   else
      o.flags = clear_flag(o.flags, 'lit')
   end

   was_dark = game.is_dark
   calculate_dark(rooms[game.current_room])

   if was_dark and game.is_dark == false then
      -- Lights are now on: look around
      r = r..'\n\n'..rooms.look_output(game.current_room)
   elseif was_dark == false and game.is_dark then
      -- Lights are now off
      r = r..'\n\n'..'You are in total darkness.'
   end
   -- Other results don't matter
   return r
end

-- GAME VERBS ==============

function game.verbs.quit (self, line)
   game.running = 0
   return 'Quitting game'
end

function game.verbs.look (self, line)
   return rooms.look_output(game.current_room)
end

-- TODO need better, more formatting, and ability for objects to describe
--      themselves.
function game.verbs.inventory (self, line)
   if game.inventory == '' then
      return 'You are not holding anything.'
   else
      return 'You are currently holding: '..game.inventory..'.'
   end
end

--
-- game.verbs.go : Travel in a direction.
--
function game.verbs.go (self, line)
   curr_room = rooms[game.current_room]

   if line[2] == nil then
      return 'Where would you like me to go?'
   end

   -- TODO: can I declare exit here if the answer is nil?
   if curr_room.exits[line[2]] == nil then
      return 'There is no way to travel in that direction.'
   end

   -- TODO: Not doing this in evaluate() because of the two return values.
   exit = curr_room.exits[line[2]]
   if type(exit) ~= 'function' then -- Simple string case
      if rooms[exit] ~= nil then
	 msg = game.goto_room(exit) -- Just a room name: go to that room.
      else
	 msg = rooms[exit] -- SORRY message
      end
   else
      -- Else, it's complicated.  Call the function and receive the name of a
      -- new room and potentially an output message.
      r,msg = exit(curr_room, line)
      if msg == nil then
	 msg = ''
      end
      if r ~= '' then
	 msg = msg..game.goto_room(r)
      end
   end
   return msg
end

-- TODO game.verbs.verbs : output verb list  see table.concat ?
-- TODO game.verbs.save / load
-- TODO game.verbs.undo


-- =================================
-- ROOMS
-- =================================
-- TODO: 'obvious exits' method
-- TODO: exits/entrances connectivity map?
-- TODO: rooms go in 'store', for separate namespace?
-- TODO: props?

rooms = {}

local function add_room (r)
-- TODO: add verbs to lexicon

   new = {
	 -- TODO : some table magic to automagically copy all fields
         id = r.id,
         name = r.name,
         verbs = r.verbs,
	 exits = r.exits,
	 look = r.look,
         contents = '',
	 flags = set_all_flags(r.flags),
   }

   -- TBD: first_depart
   new.flags = set_flag(new.flags, 'first_enter')

   lexicon.add_directions(r)

   if r.depart then
      new.depart = r.depart
   end
   if r.enter then
      new.enter = r.enter
   end

   rooms[new.id] = new
end

-- ====================
-- game.add_rooms : Add the following list (array) of rooms
function game.add_rooms (list)
   for r in ipairs(list) do
      add_room(list[r])
   end
end

function rooms.look_output (r)
   if game.is_dark then
      return 'You are in a dark place.'
   end

   output = rooms[r].name
   if rooms[r].look ~= nil then
      output = output..'\n'..evaluate(rooms[r].look)
   else
      output = output..'\n'..'You see nothing special about this place.'
   end
   if rooms[r].contents ~= '' then
      for v in string.gmatch(rooms[r].contents, "[^%s]+") do
	 o = objects.store[v]
	 if is_flag_set(o.flags, 'prop') == false then
	    if o.look then
	       output = output..'\n'..evaluate(o.look, o)
	    else
	       -- TODO: 'a' versus 'an'
	       output = output..'\nThere is a '..v..' here.'
	    end
	 end
      end
   end
   return output
end

-- =================================
-- OBJECTS
--    object flags:
--         initial : untouched.  Set at creation.  Cleared if taken, dropped,
--                   manipulated, etc.
--         prop : mentioned in room description.  Should not be called out in
--                listing of room objects.
--         TODO: hidden
--         TODO: lit
-- =================================

objects = {
   store = {},
}

local function add_object(o)
   if (objects.store[o.id] ~= nil) then
      error('WARNING: Already an object with unique ID \'', o.id, '\'.\n')
      return -1
   end

   lexicon.add_verbs(o)

   for v in string.gmatch(o.alias, "[^%s]+") do
      lexicon.add_object(v, o.id)
   end

   new = {
      id = o.id,
      name = o.name,
      location = set_all_flags(o.location),
      look = o.look,
      verbs = o.verbs,
      flags = set_all_flags(o.flags),
   }

   new.flags = set_flag(new.flags, 'initial')

   if o.state then
      new.state = o.state
   else
      new.state = ''  -- TODO: leave as nil?
   end

   -- Publish
   objects.store[o.id] = new

   for v in string.gmatch(o.location, "[^%s]+") do
      if rooms[v] then
	 rooms[v].contents = set_flag(rooms[v].contents, o.id);
      else
	 error('WARNING: object \''..o.name..'\' references non-existent location \''..v..'\'\n')
      end
   end

   -- TODO : all_things
end

function game.add_objects(new)
   for o in ipairs(new) do
      add_object(new[o])
   end
end

--============================================
-- Assorted Initialization
--============================================

function add_aliases ()
   lexicon.add_direction('n', 'north')
   lexicon.add_direction('nw', 'northwest')
   lexicon.add_direction('w', 'west')
   lexicon.add_direction('sw', 'southwest')
   lexicon.add_direction('s', 'south')
   lexicon.add_direction('se', 'southeast')
   lexicon.add_direction('e', 'east')
   lexicon.add_direction('ne', 'northeast')
   lexicon.add_direction('d', 'down')
   lexicon.add_direction('u', 'up')

   lexicon.add_verb('take', 'take')
   lexicon.add_verb('get', 'take')
   lexicon.add_verb('drop', 'drop')
   lexicon.add_verb('examine', 'examine')
   lexicon.add_verb('q', 'quit')
end

-- Initialization of this module

lexicon.add_verbs(game)
add_aliases()


-- EOF
