package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"sync"
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

var peers []Peer
var receivedMessages []Message
var messageQueue []Message
var messageQueueMutex sync.Mutex

func main() {
	peers = []Peer{
		{
			Name:      "Peer1",
			IPAddress: "127.0.0.1",
			Port:      8000,
			PossiblePeers: []string{
				"127.0.0.1:8001",
				"127.0.0.1:8002",
			},
		},
		{
			Name:      "Peer2",
			IPAddress: "127.0.0.1",
			Port:      8001,
			PossiblePeers: []string{
				"127.0.0.1:8000",
				"127.0.0.1:8002",
			},
		},
		{
			Name:      "Peer3",
			IPAddress: "127.0.0.1",
			Port:      8002,
			PossiblePeers: []string{
				"127.0.0.1:8000",
				"127.0.0.1:8001",
			},
		},
	}

	// Запуск серверов для приема сообщений
	for _, peer := range peers {
		go startServer(peer)
	}

	// Чтение команд
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		command := scanner.Text()
		switch command {
		case "send":
			sendMessage()
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

	// Добавление сообщения в очередь
	messageQueueMutex.Lock()
	receivedMessages = append(receivedMessages, message)
	messageQueueMutex.Unlock()
}

// Отправка сообщения другому пиру
func sendMessage() {
	fmt.Println("Enter sender's name:")
	reader := bufio.NewReader(os.Stdin)
	sender, _ := reader.ReadString('\n')

	fmt.Println("Enter recipient's name:")
	recipient, _ := reader.ReadString('\n')

	fmt.Println("Enter message text:")
	text, _ := reader.ReadString('\n')

	sender = strings.TrimSpace(sender)
	recipient = strings.TrimSpace(recipient)
	text = strings.TrimSpace(text)

	message := Message{
		Sender:    sender,
		Recipient: recipient,
		Text:      text,
	}

	// Отправка сообщения каждому возможному пиру
	for _, peer := range peers {
		if peer.Name == sender {
			continue // Пропускаем отправителя сообщения
		}
		err := sendMessageToPeer(peer, message)
		if err != nil {
			log.Println("Error sending message to peer:", peer.Name, err)
		}
	}
}

// Отправка сообщения указанному пиру
func sendMessageToPeer(peer Peer, message Message) error {
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", peer.IPAddress, peer.Port), time.Second*2)
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

	messageQueueMutex.Lock()
	defer messageQueueMutex.Unlock()

	for _, message := range receivedMessages {
		messageQueue = append(messageQueue, message)
	}

	for _, message := range messageQueue {
		fmt.Printf("Sender: %s, Recipient: %s, Text: %s\n", message.Sender, message.Recipient, message.Text)
	}

	// Очистка очереди сообщений
	messageQueue = nil
}
