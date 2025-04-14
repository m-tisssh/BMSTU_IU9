package main

import (
	"crypto/tls"
	"database/sql"
	"fmt"
	"log"
	"math/rand"
	"net/smtp"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

type Person struct {
	name  string
	email string
	text  string
}

func main() {
	db, err := sql.Open("mysql", "iu9networkslabs:Je2dTYr6@tcp(students.yss.su:3306)/iu9networkslabs")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatal(err)
	}
	rows, err := db.Query("select * from iu9pishikina2")
	if err != nil {
		panic(err)
	}
	defer rows.Close()
	person := []Person{}

	for rows.Next() {
		var p Person
		err := rows.Scan(&p.name, &p.email, &p.text)
		if err != nil {
			fmt.Println(err)
			continue
		}
		person = append(person, p)
	}
	for _, p := range person {
		fmt.Println("Письмо для: ", p.email)
		randomDelay := time.Duration(rand.Intn(1000)+1000) * time.Millisecond
		time.Sleep(randomDelay)

		smtpHost := "smtp.mail.ru"
		username := "iu9@bmstu.posevin.ru"
		password := "zfDYeN4tfgTDtEJY3tF7"
		smtpPort := 465
		emailTemplate := ` 
			<body style="background: #eb4034;"> 
			<p style="font-style: italic;">Добрый день, <strong>%s</strong></p> 
			<p style="font-style: italic;">%s</p> 
			</body> 
			`
		message := fmt.Sprintf("To: %s\r\nSubject: %s\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s", p.email,
			p.name, fmt.Sprintf(emailTemplate, p.name, p.text))

		tlsConfig := &tls.Config{
			InsecureSkipVerify: true,
			ServerName:         smtpHost,
		}

		conn, err := tls.Dial("tcp", fmt.Sprintf("%s:%d", smtpHost, smtpPort), tlsConfig)
		if err != nil {
			os.Exit(1)
		}

		auth := smtp.PlainAuth("", username, password, smtpHost)
		client, err := smtp.NewClient(conn, smtpHost)
		if err != nil {
			os.Exit(1)
		}

		if err := client.Auth(auth); err != nil {
			os.Exit(1)
		}

		if err := client.Mail(username); err != nil {
			os.Exit(1)
		}

		if err := client.Rcpt(p.email); err != nil {
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
	}
}
