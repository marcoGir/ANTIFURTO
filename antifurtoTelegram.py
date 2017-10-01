import socket
import threading
import sys
import time

import telepot
from telepot.delegate import per_chat_id, create_open, pave_event_space

global setAntifurto
setAntifurto=True
global antifurtoAttivato
antifurtoAttivato=False

class AstroClient(threading.Thread):

    def __init__(self, host, port, bot):
        super(AstroClient, self).__init__()
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect((host, port))
        self.data = ""
        self.bot = bot

    def run(self):
        global setAntifurto
        global antifurtoAttivato
        i=0
        while True:
            self.data = self.conn.recv(1024)
            if setAntifurto==True and self.data==b'0':
                while setAntifurto==True :
                    self.bot.send_all("apertura porte rilevata!")
                    i=i+1
                    print(i)
                    time.sleep(0.5)
                i=0

    def send_msg(self,msg):
        self.conn.send(msg)

    def close(self):
        self.conn.close()


class AstroBotTelegram():
    chat_ids = 249627759

    def __init__(self, token, host, port):
        self.bot = telepot.Bot(token)
        self.bot.message_loop(self.handle)

        self.astro_client = AstroClient(host,port, self)
        self.astro_client.daemon = True
        self.astro_client.start()

    def send_all(self, to_send):
            self.bot.sendMessage(249627759, to_send)

    
        

    def handle(self, msg):
        global setAntifurto
        global antifurtoAttivato
        content_type, chat_type, chat_id = telepot.glance(msg)

        if content_type != 'text':
            self.bot.sendMessage(chat_id,'comando errato!')
            return

        command = msg['text'].strip().lower()

        
        if command == '/avvia_antifurto':
            if chat_id==249627759:
                self.bot.sendMessage(chat_id, "Fatto, l' antifurto è attivo!")
                setAntifurto=True
                print('setAntifurto: ',setAntifurto)

        elif command == '/disattiva_antifurto':
            if chat_id==249627759:
                self.bot.sendMessage(chat_id, "Fatto, l' antifurto è disattivato")
                setAntifurto=False
                print('setAntifurto: ',setAntifurto)

        
                
        
        
            
def main():
    
    
    TOKEN ='379783514:AAGzRiOPUzk6-BWPYgeHgmf8YRjIgOkl1Dw'
    host = ''
    port = 32580
    bot = AstroBotTelegram(TOKEN, host, port)

    
    while True:
        time.sleep(1)
if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('closing')
