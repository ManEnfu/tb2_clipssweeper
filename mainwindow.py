import sys
import random
import PySide2.QtWidgets as q
from PySide2.QtCore import Slot, Qt, QObject, SIGNAL, SLOT, QSignalMapper
import minesweeper
import minesweeperlog
class MinesweeperWidget(q.QWidget):
    def __init__(self, size):
        super().__init__()
        self.size = size
        self.grid = q.QGridLayout()
        self.buttons = [[q.QPushButton(" ") for i in range(size)] for j in range(size)]
        self.row = [q.QHBoxLayout() for i in range(size)]
        self.mapper = QSignalMapper()
        self.msw = minesweeper.Minesweeper(10)
        self.mswlog = minesweeperlog.MinesweeperLog()
        for i in range(size):
            for j in range(size):
                # self.buttons[i][j].setEnabled(False)
                self.buttons[i][j].setMaximumSize(30, 30)
                self.buttons[i][j].setMinimumSize(30, 30)
                self.buttons[i][j].setStyleSheet('background-color: blue; color: black')
                self.grid.addWidget(self.buttons[i][j], i, j)
                self.mapper.setMapping(self.buttons[i][j], i * size + j)
                QObject.connect(self.buttons[i][j], SIGNAL('clicked()'), self.mapper, SLOT('map()'))

        QObject.connect(self.mapper, SIGNAL('mapped(int)'), self, SLOT('on_click(int)'))
        self.setLayout(self.grid)
        self.setMaximumSize(35 * size, 35 * size)

    def on_click(self, i):
        r = i // self.size
        c = i % self.size
        print(r, c)
        self.msw.toggle_mine(r, c)
        print("toogle mine")

    def show_state(self):
        mswlog_item = self.msw
        for i in range(self.size):
            for j in range(self.size):
                tile = mswlog_item.matrix[i][j]
                if tile.open:
                    self.buttons[i][j].setStyleSheet('background-color: white; color: black')
                    self.buttons[i][j].setEnabled(False)
                    if tile.mine:
                        self.buttons[i][j].setText('*')
                    elif tile.num == 0:
                        self.buttons[i][j].setText(' ')
                    else:
                        self.buttons[i][j].setText(str(tile.num))
                else:
                    self.buttons[i][j].setStyleSheet('background-color: blue; color: black')
                    self.buttons[i][j].setEnabled(True)
                    if tile.flag:
                        self.buttons[i][j].setText('F')
                    else:
                        self.buttons[i][j].setText(' ')
                if self.msw.recent_act == (i, j):
                    self.buttons[i][j].setStyleSheet('background-color: green; color: black')



class MainWindow(q.QWidget):
    def __init__(self):
        super().__init__()
        
        self.button = q.QPushButton("Confirm")
        self.table = MinesweeperWidget(10)
        self.next = q.QPushButton("Next")
        self.textbox = q.QTextEdit()
        self.textbox.setReadOnly(True)
        self.textbox.setText("Step 0\n\nReasoning:")
        self.textbox.setMinimumSize(300, 100)

        self.layout = q.QHBoxLayout()
        self.right_panel_layout = q.QVBoxLayout()

        self.right_panel_layout.addWidget(self.textbox)
        self.right_panel_layout.addWidget(self.button)
        self.layout.addWidget(self.table)
        self.layout.addLayout(self.right_panel_layout)
        self.setLayout(self.layout)

        # Connecting the signal
        self.button.clicked.connect(self.on_click)

    @Slot()
    def on_click(self):
        self.table.msw.start_game()
        self.table.mswlog.log_state(self.table.msw)
        self.setLayout(self.right_panel_layout)
        self.show()
        self.button.hide()
        self.right_panel_layout.addWidget(self.next)
        self.next.clicked.connect(self.next_step_minesweeper)
            
        

    @Slot()
    def next_step_minesweeper(self):
        if self.table.msw.game == minesweeper.IN_GAME:
            self.table.msw.next_clips_iter()
            self.table.mswlog.log_state(self.table.msw)
            self.table.mswlog.log_reason()
            self.table.show_state()
            self.textbox.setText(str(self.table.mswlog))
            self.table.mswlog.display()
        else:
            self.next.clicked.disconnect()
if __name__ == "__main__":
    app = q.QApplication(sys.argv + ['-style','Fusion'])

    widget = MainWindow()
    widget.resize(100, 100)
    widget.show()

    sys.exit(app.exec_())
