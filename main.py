import clips
from minesweeper import *
from minesweeperlog import *

def main():
    msw = Minesweeper(5)
    msw.toggle_mine(2, 2)
    msw.env.eval('(watch rules)')
    msw.env.eval('(watch facts)')
    msw.start_game()
    mswlog = MinesweeperLog()
    mswlog.log_state(msw)
    i = 1
    while msw.game == IN_GAME and i < 100:
        msw.next_clips_iter()
        mswlog.log_state(msw)
        mswlog.log_reason()
        msw.display()
        i += 1
    mswlog.display()
    print(msw.game)

if __name__ == '__main__':
    main()
