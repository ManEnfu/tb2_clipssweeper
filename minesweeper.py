import clips

IN_GAME = 0
WIN = 1
LOSE = 2
INIT = 3

class MinesweeperTile:
    def __init__(self):
        self.open = False
        self.flag = False
        self.mine = False
        self.num = 0

class Minesweeper:

    def __init__(self, size):
        self.size = size
        self.mines = size
        self.matrix = [
            [MinesweeperTile() for i in range(size)] 
            for j in range(size)
        ]
        self.game = INIT

    def toggle_mine(self, i, j):
        if self.game != INIT:
            return
        inc = 1
        if self.matrix[i][j].mine:
            inc = False
        self.matrix[i][j].mine = not self.matrix[i][j].mine
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

    def start_game(self):
        if self.game == INIT:
            self.game = IN_GAME

    def open(self, x, y):
        if self.game == IN_GAME and not self.matrix[x][y].open and not self.matrix[x][y].flag:
            self.matrix[x][y].open = True
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

    def open_expand(self, expands, x, y):
        if x >= 0 and x < self.size and y >= 0 and y < self.size:
            if not self.matrix[x][y].open and not self.matrix[x][y].flag:
                self.matrix[x][y].open = True
                if self.matrix[x][y].num == 0:
                    expands.append((x, y))

    def flag(self, x, y):
        if self.game == IN_GAME and not self.matrix[x][y].open and not self.matrix[x][y].flag:
            self.matrix[x][y].flag = True

    def to_str(self):
        temp = ''
        for i in range(self.size):
            for j in range(self.size):
                tile = self.matrix[i][j]
                if tile.open or self.game == INIT:
                    if tile.mine:
                        temp += '* '
                    elif tile.num == 0:
                        temp += '  '
                    else:
                        temp += str(tile.num) + ' '
                else:
                    if tile.flag:
                        temp += 'F '
                    else:
                        temp += '# '
            temp += '\n'
        return temp
    
    def display(self):
        print(self.to_str())

    def send_to_clips(self, env: clips.Environment):
        tile_open_template = env.find_template('tile-open')
        tile_closed_check = env.find_template('tile-flag')
        env.assert_string('(size {})'.format(self.size))
        for i in range(self.size):
            for j in range(self.size):
                tile = self.matrix[i][j]
                if tile.open:
                    fact = tile_open_template.new_fact()
                    fact['row'] = i
                    fact['col'] = j
                    fact['mine-count'] = tile.num
                    fact.assertit()
                elif tile.flag:
                    fact = tile_closed_check.new_fact()
                    fact['row'] = i
                    fact['col'] = j
                    fact.assertit()

    def act_from_clips(self, env: clips.Environment):
        for f in env.facts():
            if f.template.name == 'flag-tile':
                self.flag(int(f['row']), int(f['col']))
            elif f.template.name == 'open-tile':
                self.open(int(f['row']), int(f['col']))
