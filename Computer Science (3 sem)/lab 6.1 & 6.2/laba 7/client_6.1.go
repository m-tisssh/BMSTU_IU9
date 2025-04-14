package main

import (
	"crypto/tls"
	"fmt"
	"net/smtp"
	"os"
)

func main() {
	var toEmail, subject, messageBody string

	fmt.Print("Введите адрес получателя: ")
	fmt.Scanln(&toEmail)

	fmt.Print("Введите тему письма: ")
	fmt.Scanln(&subject)

	fmt.Print("Введите текст сообщения: ")
	fmt.Scanln(&messageBody)

	smtpHost := "smtp.mail.ru"
	smtpPort := 465
	username := "iu9@bmstu.posevin.ru"
	password := "zfDYeN4tfgTDtEJY3tF7"

	message := fmt.Sprintf("To: %s\r\nSubject: %s\r\n\r\n%s", toEmail, subject, messageBody)

	tlsConfig := &tls.Config{
		InsecureSkipVerify: true,
		ServerName:         smtpHost,
	}

	conn, err := tls.Dial("tcp", fmt.Sprintf("%s:%d", smtpHost, smtpPort), tlsConfig)
	if err != nil {
		os.Exit(1)
	}

	// Авторизация на SMTP сервере
	auth := smtp.PlainAuth("", username, password, smtpHost)
	client, err := smtp.NewClient(conn, smtpHost)
	if err != nil {
		os.Exit(1)
	}

	if err := client.Auth(auth); err != nil {
		os.Exit(1)
	}

	// Отправка сообщения
	if err := client.Mail(username); err != nil {
		os.Exit(1)
	}

	if err := client.Rcpt(toEmail); err != nil {
		os.Exit(1)
	}

	w, err := client.Data()
	if err != nil {
		os.Exit(1)
	}
	defer w.Close()

	_, err = w.Write([]byte(message))
	if err != nil {
		os.Exit(1)
	}

	fmt.Println("Письмо отправлено")
	client.Quit()
}
