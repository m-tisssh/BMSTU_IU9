package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var (
	lampBitovka bool
	lastTimeOn  time.Time
	duration    time.Duration
	client      *http.Client // HTTP-клиент для запросов к IOTDacha
	panelURL    = "https://iocontrol.ru/board/IOTDacha"
	buttonID    = "button1" // Идентификатор кнопки на панели
	isRecording bool        // флаг для определения записи времени
	lastTimeOff time.Time   // время последнего выключения
)

func main() {
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println(err)
			return
		}
		defer conn.Close()

		for {
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println(err)
				break
			}

			log.Println("Received data:", string(message)) // Вывод полученных данных

			var data struct {
				Value int `json:"value"`
			}
			err = json.Unmarshal(message, &data)
			if err != nil {
				log.Println(err)
				break
			}

			// Обработка переключения кнопки
			if data.Value == 0 {
				if lampBitovka {
					isRecording = true
					lastTimeOff = time.Now()
				}
				lampBitovka = false
			} else if data.Value == 1 {
				if !lampBitovka {
					loggingDuration()
				}
				lampBitovka = true
			}

			// Выполняем вычисления и возвращаем результат обратно клиенту
			result := 0
			if lampBitovka {
				result = 1
			}

			response := struct {
				Result   int    `json:"result"`
				Message  string `json:"message"`
				Duration string `json:"duration,omitempty"`
			}{
				Result:   result,
				Message:  "Received data",
				Duration: formatDuration(),
			}
			responseJSON, err := json.Marshal(response)
			if err != nil {
				log.Println(err)
				break
			}
			err = conn.WriteMessage(websocket.TextMessage, responseJSON)
			if err != nil {
				log.Println(err)
				break
			}

		}
	})

	err := http.ListenAndServe(":8970", nil)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Normal")

}

func loggingDuration() {
	if isRecording {
		isRecording = false
		lastTimeOn = lastTimeOff
		duration = time.Since(lastTimeOn)
	}
}

func formatDuration() string {
	if lampBitovka && duration != 0 {
		return duration.String()
	}
	return ""
}
