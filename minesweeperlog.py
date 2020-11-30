'''
MinesweeperLog Module

Module ini berguna untuk mengatur penyimpanan log pada KBS
Penyimpanan dan penampilan log dan reason dari suatu aksi
'''

from minesweeper import *
import os
import copy

class MinesweeperTileLog:
    '''
    MinesweeperTileLog Class

    Kelas ini berfungsi untuk menyimpan data terkait status suatu tile
    '''
    def __init__(self):
        self.open = False
        self.flag = False
        self.mine = False
        self.num = 0

class MinesweeperLogItem:
    '''
    MinesweeperLogItem Class

    Kelas ini berfungsi untuk menyimpan data terkait aksi yang dilakukan pada papan
    '''
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
        '''
        Mengkonversi suatu state papan menjadi string
        Nantinya akan di print
        '''
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
        '''
        Menampilkan status papan saat ini
        '''
        print(self.to_str())

class MinesweeperLog:
    '''
    MinesweeperLog Class
    
    Kelas ini berfungsi untuk menyimpan data terkait log 
    Log didapat dari CLIPS dan akan dituliskan ke dalam logfile .log
    Data akan dibaca dari .log dan di print
    '''
    def __init__(self):
        self.items = list()
        self.reasons = list()

    def log_state(self, msw):
        '''
        Menambahkan log berisi state ke dalam atribut kelas
        '''
        item = MinesweeperLogItem(msw)
        self.items.append(item)

    def log_reason(self):
        '''
        Menambah log berisi alasan atau reasoning ke dalam atribut kelas
        '''
        log = ''
        if (os.path.isfile('./.log')):
            logf = open('./.log', 'r')
            log = logf.read()
            logf.close()
        self.reasons.append(log)

    def display(self):
        '''
        Menampilkan log lengkap yang berisi state dan alasan ke layar
        '''
        for i in range(len(self.reasons)):
            self.items[i].display()
            print(self.reasons[i])
        self.items[len(self.reasons)].display()
    
    def __str__(self):
        '''
        Mentranslasikan daftar reason yang masih berupa list
        Menjadi 1 string
        '''
        result = ""
        for i in range(len(self.reasons)):
            result += str(self.reasons[i]) + "\n"
        return result
        

