package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"time"
)

type Peer struct {
	Name          string   `json:"name"`
	IPAddress     string   `json:"ip_address"`
	Port          int      `json:"port"`
	PossiblePeers []string `json:"possible_peers"`
}

type Message struct {
	Sender    string `json:"sender"`
	Recipient string `json:"recipient"`
	Text      string `json:"text"`
}

var receivedMessages []Message

func main() {
	peer := Peer{
		Name:      "Peer1",
		IPAddress: "185.139.70.64",
		Port:      8111,
		PossiblePeers: []string{
			"185.104.249.105:8112",
			//"185.255.133.113:8113",
		},
	}

	go startServer(peer)

	// Чтение команд
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		command := scanner.Text()
		switch command {
		case "send":
			sendMessage(peer)
		case "print":
			printReceivedMessages()
		default:
			fmt.Println("Unknown command")
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}

// Запуск сервера
func startServer(peer Peer) {
	address := fmt.Sprintf("%s:%d", peer.IPAddress, peer.Port)
	listener, err := net.Listen("tcp", address)
	if err != nil {
		log.Fatal(err)
	}
	defer listener.Close()

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Println(err)
			continue
		}

		go handleConnection(conn)
	}
}

// Обработка подключения
func handleConnection(conn net.Conn) {
	defer conn.Close()

	decoder := json.NewDecoder(conn)
	var message Message
	err := decoder.Decode(&message)
	if err != nil {
		log.Println("Error decoding message:", err)
		return
	}

	// Добавление сообщения в список полученных
	receivedMessages = append(receivedMessages, message)
}

// Отправка сообщения другому пиру
func sendMessage(peer Peer) {
	fmt.Println("Enter recipient's name:")
	reader := bufio.NewReader(os.Stdin)
	recipient, _ := reader.ReadString('\n')

	fmt.Println("Enter message text:")
	text, _ := reader.ReadString('\n')

	recipient = strings.TrimSpace(recipient)
	text = strings.TrimSpace(text)

	message := Message{
		Sender:    peer.Name,
		Recipient: recipient,
		Text:      text,
	}

	// Отправка сообщения каждому возможному пиру
	for _, possiblePeer := range peer.PossiblePeers {
		err := sendMessageToPeer(possiblePeer, message)
		if err != nil {
			log.Println("Error sending message to peer:", possiblePeer, err)
		}
	}
}

// Отправка сообщения указанному пиру
func sendMessageToPeer(peer string, message Message) error {
	conn, err := net.DialTimeout("tcp", peer, time.Second*2)
	if err != nil {
		return err
	}
	defer conn.Close()

	// Запись сообщения в соединение
	encoder := json.NewEncoder(conn)
	err = encoder.Encode(message)
	if err != nil {
		return err
	}

	return nil
}

// Вывод полученных сообщений
func printReceivedMessages() {
	fmt.Println("Received Messages:")

	for _, message := range receivedMessages {
		fmt.Printf("Sender: %s, Recipient: %s, Text: %s\n", message.Sender, message.Recipient, message.Text)
	}

	// Обнуление списка сообщений
	receivedMessages = []Message{}
}
