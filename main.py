import clips
from minesweeper import *

def main():
    env = clips.Environment()
    env.load('clp/minesweeper.clp')
    msw = Minesweeper(10)
    msw.toggle_mine(0, 6)
    msw.toggle_mine(2, 2)
    msw.toggle_mine(2, 4)
    msw.toggle_mine(3, 3)
    msw.toggle_mine(4, 2)
    msw.toggle_mine(5, 6)
    msw.toggle_mine(6, 2)
    msw.toggle_mine(7, 8)
    msw.start_game()
    msw.display()
    i = 1
    while msw.game == IN_GAME:
        print('======================== PHASE', i)
        env.reset()
        msw.send_to_clips(env)
        env.run()
        msw.act_from_clips(env)
        msw.display()
        i += 1
    print(msw.game)

if __name__ == '__main__':
    main()
