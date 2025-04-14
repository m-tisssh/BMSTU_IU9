package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	url := "ws://185.139.70.64:8666/"
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	go readResult(conn)

	reader := bufio.NewReader(os.Stdin)

	for {
		fmt.Print("Введите значение (0 или 1): ")
		value, _ := reader.ReadString('\n')
		value = value[:len(value)-1] // удаление символа новой строки

		// message в формате JSON
		message := struct {
			Value int `json:"value"`
		}{
			Value: parseValue(value),
		}

		// кодирование message в JSON
		messageJSON, err := json.Marshal(message)
		if err != nil {
			log.Println(err)
			continue
		}

		// отправка message на сервер
		err = conn.WriteMessage(websocket.TextMessage, messageJSON)
		if err != nil {
			log.Println(err)
			continue
		}

		// мини-ожидание
		time.Sleep(500 * time.Millisecond)
	}
}

func readResult(conn *websocket.Conn) {
	for {
		// чтение message от сервера
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			break
		}

		var result struct {
			Result   int    `json:"result"`
			Duration string `json:"duration,omitempty"`
		}
		err = json.Unmarshal(message, &result)
		if err != nil {
			log.Println(err)
			break
		}

		// вывод
		log.Println("Результат:", result.Result)
		if result.Duration != "" {
			log.Println("Длительность:", result.Duration)
		}
	}
}

// преобразование значения в число
func parseValue(value string) int {
	if value == "0" {
		return 0
	} else if value == "1" {
		return 1
	}
	return -1
}
