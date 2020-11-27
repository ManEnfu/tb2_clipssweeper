import clips
from minesweeper import *

def main():
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
    while msw.game == IN_GAME and i < 100:
        print('======================== PHASE', i)
        msw.next_clips_iter()
        msw.display()
        i += 1
    print(msw.game)

if __name__ == '__main__':
    main()
