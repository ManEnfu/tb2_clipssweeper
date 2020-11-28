import sys
import random
import PySide2.QtWidgets as q
from PySide2.QtCore import Slot, Qt, QObject, SIGNAL, SLOT, QSignalMapper

class MinesweeperWidget(q.QGridLayout):
    def __init__(self, size):
        super().__init__()
        self.size = size
        self.buttons = [[q.QPushButton("2") for i in range(size)] for j in range(size)]
        self.row = [q.QHBoxLayout() for i in range(size)]
        self.mapper = QSignalMapper()

        for i in range(size):
            for j in range(size):
                # self.buttons[i][j].setEnabled(False)
                self.buttons[i][j].setMaximumSize(30, 30)
                self.buttons[i][j].setMinimumSize(30, 30)
                self.addWidget(self.buttons[i][j], i, j)
                self.mapper.setMapping(self.buttons[i][j], i * size + j)
                QObject.connect(self.buttons[i][j], SIGNAL('clicked()'), self.mapper, SLOT('map()'))

        QObject.connect(self.mapper, SIGNAL('mapped(int)'), self, SLOT('on_click(int)'))

    def on_click(self, i):
        r = i // self.size
        c = i % self.size
        print(r, c)

    def show_state(self, msw):
        pass



class MainWindow(q.QWidget):
    def __init__(self):
        super().__init__()

        self.button = q.QPushButton("Confirm")
    
        self.table = MinesweeperWidget(10)


        self.layout = q.QHBoxLayout()
        self.layout.addLayout(self.table)
        self.layout.addWidget(self.button)
        self.setLayout(self.layout)

        # Connecting the signal
        self.button.clicked.connect(self.on_click)

    @Slot()
    def on_click(self):
        pass
if __name__ == "__main__":
    app = q.QApplication(sys.argv + ['-style','Fusion'])

    widget = MainWindow()
    widget.resize(100, 100)
    widget.show()

    sys.exit(app.exec_())
