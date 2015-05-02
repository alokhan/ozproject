functor
import
   Utils
   Map
   BattleUtils

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

   fun {NewGameState}
      %% This object memorize the current state of the game (running, waiting, finished)
      %% Available messages :
      %%    run
      %%    wait
      %%    finish
      %%    get(ret(RETURN))
      %%       where RETURN is an unbound variable

      InitGameState = waiting

      fun {FunGameState S Msg}
         if S == finished then finished
         else
            case Msg
            of run then running
            [] wait(Ack) then Ack=unit waiting
            [] get(ret(R)) then R=S S
            end
         end
      end
   in
      {Utils.newPortObject InitGameState FunGameState}
   end

   proc {StartGameServer MapLayout NPCsP PCP TicTime WildProba}
      GameState = {NewGameState}
      thread {Tic NPCs TicTime} end
      {Map.setupMap MapLayout PCP}
      {BattleUtils.setupBattle WildProba}
      {Send GameState run}
      NPCs = NPCsP
      PC = PCP
      {NotifyMapChanged}
      {Map.addMsgConsole "Welcome to pokemoz !"}
   end

   proc {StopGameServer Status}
      %% This proc stops the server and display the victory / defeat notification
      {Send GameState finish}
      if status == victory then
         {Utils.printf "Congratulations, you have won the game."}
         {Utils.printf "Jay would be so proud of you."}
      else
         {Utils.printf "Doom doom doom..."}
         {Utils.printf "You have lost the game."}
         {Utils.printf "You must play more to be the very best !"}
      end
   end

   proc {Tic NPCs Time}
      R in
      {Delay Time}
      {SendPlayersNotification move(Time) NPCs}
      {SendPlayersNotification look NPCs}
      {Tic NPCs Time}
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
      {Map.redraw NPCs PC}
   end

   fun {IsPosFree Pos}
      %% Return false if a trainer in on this position pos(x:X y:Y), true otherwise

      fun {IsPosFreeRec Pos Trainers}
         case Trainers
         of H|T then
            local R in
            {Send H get(position ret(R))}
            if R == Pos then
               false
            else
               {IsPosFreeRec Pos T}
            end end
         [] nil then
            true
         end
      end
   in
      {IsPosFreeRec Pos PC|NPCs}
   end

end
