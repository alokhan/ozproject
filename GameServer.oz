functor
import
   Utils
   OS
export
   GameServer
define
   DELAY = 200
   fun {GameServer Map Players WILDPOKEMOZPROBA}

      % function to see if there is a wild pokemoz in the grass
      fun {IsThereWildPokemoz}
	 ({OS.rand} mod 100) < WILDPOKEMOZPROBA 
      end

      % Generate a random pokemoz with a min level of 5 and a random extra level depending on other pokemon
      fun {GenerateRandomPokemoz Pokemoz}
	 local T Lvl in
	    T = ({OS.rand} mod 3)+1
            Lvl = 5 %+ ({OS.rand} mod (Pokemoz.lvl-5))
	    pokemoz(hp:Utils.pokemozMaxHp.Lvl lvl:Lvl type:Utils.pokemozType.T maxhp:Utils.pokemozMaxHp.Lvl name:"wild pokemoz" xp:0)
	 end
      end

      fun {GetDamages Pokemoz1 Pokemoz2}
	 local Proba R in 
	    Proba = (( 6 + Pokemoz1.lvl - Pokemoz2.lvl) * 9)
	    R = {OS.rand}  mod 101
	    if R > Proba then
	       %{Utils.printf Pokemoz1.name#" attack failed"}
	       0
	    else
	       %{Utils.printf Pokemoz1.name#" attack succeded"}
	       if Pokemoz1.type == Pokemoz2.type then
		  2
	       elseif Pokemoz1.type == grass then
		  if Pokemoz2.type == fire then
		     1
		  else
		     3
		  end
	       elseif Pokemoz1.type == fire then
		  if Pokemoz2.type == grass then
		     3
		  else
		     1
		  end
	       elseif Pokemoz1.type == water then
		  if Pokemoz2.type == grass then
		     1
		  else
		     3
		  end
	       end
	    end
	 end
      end

      fun {Fight Pokemoz1 Pokemoz2}
	 if Pokemoz1.hp > 0 andthen Pokemoz2.hp > 0 then
	    local DamageBy1 DamageBy2 NewPok1 NewPok2 in
	       DamageBy1 = {GetDamages Pokemoz1 Pokemoz2}
	       DamageBy2 = {GetDamages Pokemoz2 Pokemoz1}
	       NewPok1 = pokemoz(type:Pokemoz1.type maxhp:Pokemoz1.maxhp hp:Pokemoz1.hp-DamageBy2 lvl:Pokemoz1.lvl name:Pokemoz1.name xp:Pokemoz1.xp)
	       NewPok2 = pokemoz(type:Pokemoz2.type maxhp:Pokemoz2.maxhp hp:Pokemoz2.hp-DamageBy1 lvl:Pokemoz2.lvl name:Pokemoz2.name xp:Pokemoz2.xp)
	       {Fight NewPok1 NewPok2}
	    end
	 else
	    if Pokemoz1.hp > 0 then
	       fightresult({GainXP Pokemoz1 Pokemoz2.lvl} win)
	    else
	       fightresult(Pokemoz1 lost)
	    end
	 end
      end

      fun {GainXP Pokemoz XP}
	local IndexLvl CurrentXP NeededXPToLvlUp NewXP NewLvl NewMaxHp in
          CurrentXP = Pokemoz.xp + XP
          IndexLvl = Pokemoz.lvl-4
          NeededXPToLvlUp = Utils.pokemozXPNeeded.IndexLvl
          if CurrentXP > NeededXPToLvlUp then
            NewXP = CurrentXP - NeededXPToLvlUp
            NewLvl = Pokemoz.lvl+1
            NewMaxHp = Utils.pokemozMaxHp.(NewLvl-4)
            pokemoz(type:Pokemoz.type maxhp:NewMaxHp hp:NewMaxHp lvl:NewLvl name:Pokemoz.name xp:NewXP)
          else
            pokemoz(type:Pokemoz.type maxhp:Pokemoz.maxhp hp:Pokemoz.hp lvl:Pokemoz.lvl name:Pokemoz.name xp:CurrentXP)
          end  
	end
      end

      % get what type of area is at that position
      fun {GetAt Map X Y}
	 local WidthInCell HeightInCell in
	    WidthInCell = {Record.width Map.1}
	    HeightInCell = {Record.width Map}
	    if X > 0 andthen X =< WidthInCell andthen Y > 0 andthen Y =< HeightInCell then
	       Map.Y.X
	    else
	       ~1
	    end
	 end
      end
 
      fun {CheckValidPosition Position}
	 local WidthInCell HeightInCell in
	    WidthInCell = {Record.width Map.1}
	    HeightInCell = {Record.width Map}
	    if Position.x > 0 andthen Position.x =< WidthInCell andthen Position.y > 0 andthen  Position.y =< HeightInCell then
	       true
	    else
	       false
	    end
	 end
      end

      % Update a player position in the player list.
      fun {UpdatePlayerPosition Id Player NewPosition}
	 local NewPlayers in
	    NewPlayers = {MakeTuple players {Width Players}}
	    for I in 1..{Width Players} do
	       if I == Id then
		  NewPlayers.I = player(port:Player.port pos:NewPosition)   
	       else
		  NewPlayers.I = Players.I
	       end
	    end
	    NewPlayers
	 end
      end
	


      fun {Inbox State Msg}
	 case State of state(starting Map Players) then
	    case Msg of start then
	       %Start the game tell the player to pick a pokemoz
	       for I in 1..{Width Players} do
		  {Send Players.I.port pickpokemoz}
		  {Send Players.I.port mapchanged(Map Players)}
	       end
	       state(listening Map Players)
	    else
	       {Utils.printf "server not started please start the server"}
	    end
	 [] state(listening Map Players) then
	    case Msg of stop then
	       state(stopped)
	    [] round(I) then
	       {Send Players.I.port play(Players.I.pos)}
	       State
            [] getplayers(Id P) then
               P = Players.Id.port
               State
	    [] move(Id Position Direction) then
	       local Obj UpdatedPlayers Wild in
		  % Get what type of area it is at that position (grass/road/trainer)
		  Obj = {GetAt Map Position.x Position.y}
		  if {Label Players.Id} == dead then
		     {Send Players.Id.port invalid(dead Players.Id.pos)}
		     State
		  % Check if the position the player want to move to is valid
		  elseif {CheckValidPosition Position} == false then
		     {Send Players.Id.port invalid(wrongmove Players.Id.pos)}
		     State
		  else
		     UpdatedPlayers = {UpdatePlayerPosition Id Players.Id Position}
		     {Send UpdatedPlayers.Id.port mapchanged(Map UpdatedPlayers)}
		     % if we are in a grass area check wilpokemoz, danger ! 
		     if Obj == 1 then
			if {IsThereWildPokemoz} == true then
			   local P in
                           {Send Players.Id.port getpokemoz(P)}
			   {Send Players.Id.port wildpokemoz({GenerateRandomPokemoz P})}
			   end
			end
		     end
		     state(listening Map UpdatedPlayers)
		  end
	       end
	    [] runway(Id WildPokemoz) then
	       {Utils.printf "Run away from a wild pokemon CHICKEN :D"}
	       State
	    [] fight(Id PlayerPokemoz OtherPokemoz) then
	       {Utils.printf "fighting a pokemon"}
	       {Send Players.Id.port {Fight PlayerPokemoz OtherPokemoz}}
	       State
	    [] quit() then
	       {Utils.printf "Disconnecting from game"}
	    end
	 [] state(stopped) then
	    state(stopped)
	 end
      end
   in
      {Utils.newPortObject state(starting Map Players) Inbox}
   end
end
