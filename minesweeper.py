import clips

IN_GAME = 0
WIN = 1
LOSE = 2
INIT = 3

class MinesweeperTile:
    def __init__(self):
        self.open = False   # Is tile opened?
        self.flag = False   # Is tile flagged? 
        self.mine = False   # Does tile have mine on it?
        self.num = 0        # Number of adjacent mines

class Minesweeper:

    # Construct new Minesweeper Game
    def __init__(self, size):
        self.size = size
        # Initialize tiles
        self.matrix = [
            [MinesweeperTile() for i in range(size)] 
            for j in range(size)
        ]
        self.game = INIT
        self.env = clips.Environment()  # Connect CLIPS environment to the game
        self.recent_act = (-1, -1)      # Recent tile to be acted upon

    # Put / take away mine on a tile
    def toggle_mine(self, i, j):
        if self.game != INIT:
            return
        inc = 1
        if self.matrix[i][j].mine:
            inc = False
        self.matrix[i][j].mine = not self.matrix[i][j].mine
        # Increment/decrement num value of adjacent tiles
        if i > 0:
            if j > 0:
                self.matrix[i - 1][j - 1].num += inc
            self.matrix[i - 1][j].num += inc
            if j < self.size - 1:
                self.matrix[i - 1][j + 1].num += inc
        if j > 0:
            self.matrix[i][j - 1].num += inc
        if j < self.size - 1:
            self.matrix[i][j + 1].num += inc
        if i < self.size - 1:
            if j > 0:
                self.matrix[i + 1][j - 1].num += inc
            self.matrix[i + 1][j].num += inc
            if j < self.size - 1:
                self.matrix[i + 1][j + 1].num += inc

    # Start game
    def start_game(self):
        if self.game == INIT:
            self.env.load('clp/minesweeper.clp')
            # self.env.eval('(watch rules)')
            # self.env.eval('(watch facts)')
            self.env.reset()
            self.env.assert_string('(size {})'.format(self.size))
            self.game = IN_GAME

    # Open tile.
    def open(self, x, y):
        if self.game == IN_GAME and not self.matrix[x][y].open and not self.matrix[x][y].flag:
            self.matrix[x][y].open = True
            self.recent_act = (x, y)
            # assert fact
            tile_open_template = self.env.find_template('tile-open')
            fact = tile_open_template.new_fact()
            fact['row'] = x
            fact['col'] = y
            fact['mine-count'] = self.matrix[x][y].num
            fact.assertit()
            if self.matrix[x][y].mine:
                self.game = LOSE
                return
            expands = list()
            if self.matrix[x][y].num == 0:
                expands.append((x, y))
            while len(expands) > 0:
                (i, j) = expands[0]
                self.open_expand(expands, i - 1, j - 1)
                self.open_expand(expands, i - 1, j)
                self.open_expand(expands, i - 1, j + 1)
                self.open_expand(expands, i, j - 1)
                self.open_expand(expands, i, j + 1)
                self.open_expand(expands, i + 1, j - 1)
                self.open_expand(expands, i + 1, j)
                self.open_expand(expands, i + 1, j + 1)
                del expands[0]
        self.check_win()

    # Intermediate method for flood opening
    def open_expand(self, expands, x, y):
        if x >= 0 and x < self.size and y >= 0 and y < self.size:
            if not self.matrix[x][y].open and not self.matrix[x][y].flag:
                self.matrix[x][y].open = True
                # assert fact
                tile_open_template = self.env.find_template('tile-open')
                fact = tile_open_template.new_fact()
                fact['row'] = x
                fact['col'] = y
                fact['mine-count'] = self.matrix[x][y].num
                fact.assertit()
                if self.matrix[x][y].num == 0:
                    expands.append((x, y))

    # Check win condition, game terminates if win
    def check_win(self):
        if self.game == IN_GAME:
            for row in self.matrix:
                for tile in row:
                    if tile.open and tile.mine:
                        return
                    elif not tile.open and not (tile.flag and tile.mine):
                        return
            self.game = WIN

    # Put flag on a tile
    def flag(self, x, y):
        if self.game == IN_GAME and not self.matrix[x][y].open and not self.matrix[x][y].flag:
            self.matrix[x][y].flag = True
            self.recent_act = (x, y)
            tile_open_template = self.env.find_template('tile-flag')
            fact = tile_open_template.new_fact()
            fact['row'] = x
            fact['col'] = y
            fact.assertit()

    # Convert to string
    def to_str(self):
        temp = ''
        for i in range(self.size):
            for j in range(self.size):
                tile = self.matrix[i][j]
                if self.recent_act == (i, j):
                    temp += '['
                elif self.recent_act == (i, j - 1):
                    temp += ']'
                else:
                    temp += ' '
                if tile.open or self.game == INIT:
                    if tile.mine:
                        temp += '*'
                    elif tile.num == 0:
                        temp += '.'
                    else:
                        temp += str(tile.num)
                else:
                    if tile.flag:
                        temp += 'F'
                    else:
                        temp += '#'
            if self.recent_act == (i, self.size - 1):
                temp += ']'
            temp += '\n'
        return temp
    
    def print_game_status(self):
        status = {
            IN_GAME : "IN_GAME",
            WIN : "WIN",
            LOSE : "LOSE",
            INIT : "INIT"
        }

        return "Game status : " + status[self.game]
    
    # Print to screen
    def display(self):
        print(self.to_str())

    # Apply CLIPS inference for one action
    def next_clips_iter(self):
        self.env.run()
        for f in self.env.facts():
            if f.template.name == 'flag-tile':
                self.flag(int(f['row']), int(f['col']))
            elif f.template.name == 'open-tile':
                self.open(int(f['row']), int(f['col']))
        self.env.assert_string('(phase clear-act)')

