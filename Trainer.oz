functor
import
   Utils
   GameServer
   Map
export
   NewTrainer

define

   fun {NewTrainer Pokemoz Pos Direction}
      %% This object represent a trainer (any trainer)
      %% Available messages :
      %%    move -- always forward
      %%    turn(DIRECTION)
      %%       where DIRECTION is one of the following : up down left right
      %%    fight(POKEMOZ) -- tell this trainer pokemoz to attack the other one
      %%       where POKEMOZ is an instance of the pokemoz object representing the enemy
      %%    haslost(ret(RETURN))
      %%       where RETURN in an unbound variable to be bound to either true or false
      %%    get(ATTRIBUTE ret(RETURN))
      %%       where ATTRIBUTES is one of the following : pkmz, pos, dir
      %%       and RETURN is an unbound variable

      InitTrainer = trainer(pkmz:Pokemoz pos:Pos dir:Direction)

      fun {FunTrainer S Msg}
         case Msg
         of move then
            Ack NewPos in
            case S.dir
              of up then NewPos = pos(x:S.pos.x y:(S.pos.y-1))
              [] down  then NewPos =pos(x:S.pos.x y:(S.pos.y+1))
              [] left  then NewPos =pos(x:(S.pos.x-1) y:S.pos.y)
              [] right then NewPos =pos(x:(S.pos.x+1) y:S.pos.y)
            end
            {Send GameServer.gameState moved(S.pos NewPos Ack)}
            {Wait Ack}
            % map change requires sending a message so it will wait until pos updated
            thread {GameServer.notifyMapChanged} end
            trainer(pkmz:S.pkmz pos:NewPos dir:S.dir)
         [] turn(D) then
            thread {GameServer.notifyMapChanged} end
            trainer(pkmz:S.pkmz pos:S.pos dir:D)
         [] fight(P) then
            {Send P attackedby(S.pkmz)}
            S
         [] haslost(ret(R)) then
            {Send S.pkmz isko(ret(R))}
            S
         [] get(D ret(R)) then
            R = S.D
            S
         [] setpokemoz(P) then
            trainer(pkmz:P pos:S.pos dir:S.dir)
         else
            S
         end
      end

   in
      {Utils.newPortObject InitTrainer FunTrainer}
   end

end
