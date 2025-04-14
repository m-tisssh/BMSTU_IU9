package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
	"github.com/mmcdole/gofeed"
)

func main() {
	dbHost := "students.yss.su"
	dbPort := 3306
	dbName := "iu9networkslabs"
	dbUser := "iu9networkslabs"
	dbPass := "Je2dTYr6"

	// подключение к бд
	dbURL := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s", dbUser, dbPass, dbHost, dbPort, dbName)

	db, err := sql.Open("mysql", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// если таблица не существует, то создать
	createTableQuery := `
		CREATE TABLE IF NOT EXISTS iu9pishikina (
			id INT AUTO_INCREMENT,
			title VARCHAR(255),
			description TEXT,
			link VARCHAR(255),
			pub_date DATETIME,
			PRIMARY KEY (id)
		);
	`
	_, err = db.Exec(createTableQuery)
	if err != nil {
		log.Fatal(err)
	}

	// магадан ))))
	rssURL := "https://news.rambler.ru/rss/Magadan/"

	fp := gofeed.NewParser()

	feed, err := fp.ParseURL(rssURL)
	if err != nil {
		log.Fatal(err)
	}

	// обход новостей и записать в бд
	for _, item := range feed.Items {
		// проверка наличия новости в бд
		query := "SELECT COUNT(*) FROM iu9pishikina WHERE link = ?"
		var count int
		err = db.QueryRow(query, item.Link).Scan(&count)
		if err != nil {
			log.Fatal(err)
		}

		// если новость уже существует в базе данных, пропускаем ее
		if count > 0 {
			continue
		}

		// вставить новость в бд
		insertQuery := `
			INSERT INTO iu9pishikina (title, description, link, pub_date)
			VALUES (?, ?, ?, ?)
		`
		_, err = db.Exec(insertQuery, item.Title, item.Description, item.Link, item.Published)
		if err != nil {
			log.Fatal(err)
		}
	}

	log.Println("Завершено обновление таблицы новостей.")
}
