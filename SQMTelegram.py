import socket
import threading
import sys
import time

import telepot
invioLetture=False
allertaNuvole=False
cloudLimit=1023
from telepot.delegate import per_chat_id, create_open, pave_event_space

class AstroClient(threading.Thread):

    def __init__(self, host, port, bot):
        super(AstroClient, self).__init__()
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect((host, port))
        self.data = ""
        self.bot = bot

    def run(self):
        global invioLettur
        global allertaNuvole
        global cloudLimit
        cont=0
        while True:
            self.data = self.conn.recv(1024)
            if allertaNuvole==True:
                if float(self.data)>float(cloudLimit):
                    while cont<30:
                        cont=cont+1
                        self.bot.send_all('allerta nuvole')
                        time.sleep(1)
                    cont=0
            if self.data != "":
                if invioLetture==True:
                    self.bot.send_all(self.data)
                self.data = ""

    def send_msg(self,msg):
        self.conn.send(msg)

    def close(self):
        self.conn.close()


class AstroBotTelegram():
    chat_ids = set([])

    def __init__(self, token, host, port):
        self.bot = telepot.Bot(token)
        self.bot.message_loop(self.handle)

        self.astro_client = AstroClient(host,port, self)
        self.astro_client.daemon = True
        self.astro_client.start()

    def send_all(self, to_send):
        print(self.chat_ids)
        for chat_id in self.chat_ids:
            self.bot.sendMessage(chat_id, to_send)

    def handle(self, msg):

        global allertaNuvole
        global invioLetture
        global cloudLimit
        
        content_type, chat_type, chat_id = telepot.glance(msg)

        if content_type != 'text':
            self.bot.sendMessage(chat_id,'comando errato!')
            return

        command = msg['text'].strip().lower()

        
        if command == '/attiva_invio_letture':
            if chat_id not in self.chat_ids:
                self.chat_ids.add(chat_id)
            self.bot.sendMessage(chat_id, "Fatto, riceverai le letture in tempo reale!")
            invioLetture=True
            print('invioLetture: ',invioLetture)

        elif command == '/attiva_allerta_nuvole':
            if chat_id not in self.chat_ids:
                self.chat_ids.add(chat_id)
            self.bot.sendMessage(chat_id, "Fatto, che soglia vuoi impostare?")
            allertaNuvole=True
            print('allertaNuvole: ',allertaNuvole)

        elif command == '/arresta_invio_letture':
            if chat_id not in self.chat_ids:
                self.chat_ids.add(chat_id)
            self.bot.sendMessage(chat_id, "Fatto, non riceverai piu' le letture in tempo reale!")
            invioLetture=False
            print('invioLetture: ',invioLetture)

        elif command == '/arresta_allerta_nuvole':
            if chat_id not in self.chat_ids:
                self.chat_ids.add(chat_id)
            self.bot.sendMessage(chat_id, "Fatto, non riceverai piu' un avviso in caso di annuvolamenti!")
            allertaNuvole=False
            print('allertaNuvole: ',allertaNuvole)

        else:
            cloudLimit=float(command)
            self.bot.sendMessage(chat_id,'Fatto, verrai allertato in caso di annuvolamenti!')
            print (cloudLimit)


def main():
    
    
    TOKEN ='378398659:AAEx3zsCzvPkZY2RGmgIRGeoSqVQRuR429c'
    host = ''
    port = 12345
    bot = AstroBotTelegram(TOKEN, host, port)

    
    while True:
        time.sleep(1)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('closing')
