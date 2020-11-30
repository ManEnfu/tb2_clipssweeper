from minesweeper import *
import os
import copy

class MinesweeperTileLog:
    def __init__(self):
        self.open = False
        self.flag = False
        self.mine = False
        self.num = 0

class MinesweeperLogItem:
    def __init__(self, msw):
        self.size = msw.size
        self.matrix = list()
        for i in range(msw.size):
            row = list()
            for j in range(msw.size):
                row.append(copy.copy(msw.matrix[i][j]))
            self.matrix.append(row)
        self.recent_act = msw.recent_act
    
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
                if tile.open:
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
    
    def display(self):
        print(self.to_str())

class MinesweeperLog:
    def __init__(self):
        self.items = list()
        self.reasons = list()

    def log_state(self, msw):
        item = MinesweeperLogItem(msw)
        self.items.append(item)

    def log_reason(self):
        log = ''
        if (os.path.isfile('./.log')):
            logf = open('./.log', 'r')
            log = logf.read()
            logf.close()
        self.reasons.append(log)

    def display(self):
        for i in range(len(self.reasons)):
            self.items[i].display()
            print(self.reasons[i])
        self.items[len(self.reasons)].display()
    
    def to_str_reasons(self,i):
        return str(self.reasons[i]) 

        

