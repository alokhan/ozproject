functor
import
   Utils
   Map
   BattleUtils
   PokemozMain
   Application

export
   StartGameServer
   StopGameServer
   NotifyMapChanged
   IsPosFree
   GameState
   PC

define
   GameState
   NPCs
   PC

   fun {NewGameState PosTaken}
      %% This object memorize the current state of the game (running, waiting, finished)
      %% Available messages :
      %%    run
      %%    wait
      %%    finish
      %%    get(ATTRIBUTE ret(RETURN))
      %%       where RETURN is an unbound variable

      InitGameState = game(state:waiting posTaken:PosTaken)

      fun {FunGameState S Msg}
         if S.state == finished then game(state:finished posTaken:PosTaken)
         else
            case Msg
            of run then  game(state:running posTaken:S.posTaken)
            [] wait(Ack) then Ack=unit game(state:waiting posTaken:S.posTaken)
            [] get(D ret(R)) then R=S.D S
            [] finish then game(state:finished posTaken:PosTaken)
            [] moved(From To Ack) then
              NewPosTaken in
              NewPosTaken ={RemovePositionTaken From To|S.posTaken nil}
              Ack=unit
              game(state:S.state posTaken:NewPosTaken)
            end
         end
      end
   in
      {Utils.newPortObject InitGameState FunGameState}
   end

   proc {StartGameServer MapLayout NPCsP PCP TicTime WildProba RunAway}
      PositionsTaken in
      NPCs = NPCsP
      PC = PCP
      PositionsTaken = {InitPositionTaken PC|NPCs nil}
      GameState = {NewGameState PositionsTaken}
      {Map.setupMap MapLayout PCP}
      {BattleUtils.setupBattle WildProba RunAway}
      {Send GameState run}
      {NotifyMapChanged}
      thread {Tic NPCs PC|nil TicTime} end
      {Map.addMsgConsole "Welcome to pokemoz !"}
   end

   proc {StopGameServer Status}
      %% This proc stops the server and display the victory / defeat notification
      {Send GameState finish}
      if Status == victory then
         {Map.addMsgConsole "Congratulations, you have won the game."}
         {Map.addMsgConsole "Jay would be so proud of you."}
      else
         {Map.addMsgConsole "Doom doom doom..."}
         {Map.addMsgConsole "You have lost the game."}
         {Map.addMsgConsole "You must play more to be the very best !"}
      end
      PokemozMain.finish = unit
   end

   fun {RemovePositionTaken From List NewList}
     case List of nil then NewList
     [] H|T then
        local P in
          if From.x == H.x andthen From.y == H.y then
            {RemovePositionTaken From T NewList}
          else
            {RemovePositionTaken From T H|NewList}
          end
        end
     end
   end

   fun {InitPositionTaken Trainers List}
     case Trainers of nil then List
     [] H|T then
        local P in
          {Send H get(pos ret(P))}
          {InitPositionTaken T P|List}
        end
     end
   end

   proc {Tic NPCs PC Time}
      {Delay Time}
      {SendPlayersNotification move(Time) NPCs}
      {SendPlayersNotification look NPCs}
      {SendPlayersNotification move(Time) PC}
      %{NotifyMapChanged}
      {Tic NPCs PC Time}
   end

   proc {SendPlayersNotification Notif NPCs}
      case NPCs
      of M|N then
         {Send M Notif}
         {SendPlayersNotification Notif N}
      [] nil then skip
      end
   end

   proc {NotifyMapChanged}
      CurrentGameState in
      {Send GameState get(state ret(CurrentGameState))}
      if (CurrentGameState == running) then
        {Map.draw}
        {Map.redraw NPCs PC}
      end
   end

   fun {IsPosFree Pos}
      %% Return false if a trainer in on this position pos(x:X y:Y), true otherwise

      fun {IsPosFreeRec Pos Positions}
         case Positions
         of H|T then
            local P in
            if H.x == Pos.x andthen H.y == Pos.y then
               false
            else
               {IsPosFreeRec Pos T}
            end end
         [] nil then
            true
         end
      end
      TakenPositions
   in
      {Send GameState get(posTaken ret(TakenPositions))}
      {IsPosFreeRec Pos TakenPositions}
   end

end
