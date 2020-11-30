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
        self.msw = minesweeper.Minesweeper(size)
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

        if self.msw.game == minesweeper.INIT:
            self.msw.toggle_mine(r, c)
            self.show_state(0)

    def show_state(self, log_idx):
        if self.msw.game == minesweeper.INIT:
            for i in range(self.size):
                for j in range(self.size):
                    tile = self.msw.matrix[i][j]
                    if tile.mine:
                        self.buttons[i][j].setStyleSheet('background-color: red; color: black')
                        self.buttons[i][j].setText(' ')
                    else:
                        self.buttons[i][j].setStyleSheet('background-color: blue; color: black')
                        if tile.num == 0:
                            self.buttons[i][j].setText(' ')
                        else:
                            self.buttons[i][j].setText(str(tile.num))
        else:
            mswlog_item = self.mswlog.items[log_idx]
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
                    if len(self.mswlog.items) > log_idx+1:
                        if self.mswlog.items[log_idx+1].recent_act == (i, j):
                            self.buttons[i][j].setStyleSheet('background-color: green; color: black')



class MainWindow(q.QWidget):
    def __init__(self,size):
        super().__init__()
    
        self.iter_counter = 0
        
        self.button = q.QPushButton("Confirm")
        self.table = MinesweeperWidget(size)
        self.next = q.QPushButton("Next")
        self.prev = q.QPushButton("Previous")
        self.textbox = q.QTextEdit()
        self.textbox.setReadOnly(True)
        self.textbox.setText("Put mines into tiles by clicking on it. \nPress Confirm to let the agent play the game.")
        self.textbox.setMinimumSize(300, 100)
        self.size_input = q.QTextEdit()
        self.size_input.setMinimumSize(300, 25)
        self.confirm_size = q.QPushButton("Confirm size")
        self.size_label = q.QLabel()
        self.size_label.setText("Input board size")
        self.size_label.setAlignment(Qt.AlignLeft)
        self.size_error = q.QLabel()
        self.size_error.setText("Size must be an integer")
        self.size_error.setAlignment(Qt.AlignLeft)
        self.size_error.setVisible(False)
        self.size_error.setStyleSheet("color: red")

        self.layout = q.QHBoxLayout()
        self.right_panel_layout = q.QVBoxLayout()

        self.right_panel_layout.addWidget(self.size_label)
        self.right_panel_layout.addWidget(self.size_input)
        self.right_panel_layout.addWidget(self.size_error)
        self.right_panel_layout.addWidget(self.confirm_size)
        self.layout.addLayout(self.right_panel_layout)
        self.setLayout(self.layout)

        # Connecting the signal
        self.confirm_size.clicked.connect(self.init_size)

    @Slot()
    def on_click(self):
        if self.table.msw.game == minesweeper.INIT:
            self.table.msw.start_game()
            self.table.mswlog.log_state(self.table.msw)
            
            i = 1
            while self.table.msw.game == minesweeper.IN_GAME and i < self.table.size*self.table.size :
                self.table.msw.next_clips_iter()
                self.table.mswlog.log_state(self.table.msw)
                self.table.mswlog.log_reason()
                
                i += 1
            
            self.setLayout(self.right_panel_layout)
            self.show()
            self.button.hide()
            self.right_panel_layout.addWidget(self.next)
            self.right_panel_layout.addWidget(self.prev)
            self.next.clicked.connect(self.next_step_minesweeper)
            self.prev.clicked.connect(self.prev_step_minesweeper)
            self.table.show_state(self.iter_counter)
            self.textbox.setText(self.table.mswlog.to_str_reasons(self.iter_counter))
        

    @Slot()
    def next_step_minesweeper(self):
        if self.iter_counter+1 < len(self.table.mswlog.items):
            self.table.show_state(self.iter_counter+1)
            if len(self.table.mswlog.reasons) > self.iter_counter+1:
                self.textbox.setText(self.table.mswlog.to_str_reasons(self.iter_counter+1))
            else:
                self.textbox.setText(self.table.msw.print_game_status())
            self.iter_counter += 1

    @Slot()
    def prev_step_minesweeper(self):
        if self.iter_counter > 0:
            self.table.show_state(self.iter_counter-1)
            self.textbox.setText(self.table.mswlog.to_str_reasons(self.iter_counter-1))
            self.iter_counter -= 1
    
    @Slot()
    def init_size(self):
        try:
            size = int(self.size_input.toPlainText())
            if size < 4 or size > 10:
                raise 'a'
            self.size_label.hide()
            self.size_input.hide()
            self.confirm_size.hide()
            self.size_error.hide()
            self.confirm_size.clicked.disconnect()
            
            self.table = MinesweeperWidget(size)
            self.layout.removeItem(self.right_panel_layout)
            self.layout.addWidget(self.table)
            self.right_panel_layout.addWidget(self.textbox)
            self.right_panel_layout.addWidget(self.button)
            self.layout.addLayout(self.right_panel_layout)
            self.button.clicked.connect(self.on_click)
        except:
            self.size_error.setVisible(True)

class InitWindow(q.QMainWindow):
    def __init__(self):
        super().__init__()
        self.label_value = q.QLabel()
        self.label_value.setText("Size")
        self.input_value = q.QLineEdit()
        self.button = q.QPushButton("INIT GAME")
        self.button.clicked.connect(self.show_new_window)
        
        self.layout = q.QVBoxLayout()
        
        self.layout.addWidget(self.label_value)
        self.layout.addWidget(self.input_value)
        self.layout.addWidget(self.button)
        self.button.setMinimumSize(300, 100)
        widget = q.QWidget()
        widget.setLayout(self.layout)
        self.setCentralWidget(widget)
        
        self.resize(100,100)
        self.show()

    @Slot()
    def show_new_window(self, checked):
        self.widget = MainWindow(int(self.input_value.text()))
        self.widget.resize(100, 100)
        self.widget.show()
        self.hide()


if __name__ == "__main__":
    app = q.QApplication(sys.argv + ['-style','Fusion'])
    window = MainWindow(5)
    window.show()
    
    

    sys.exit(app.exec_())
