package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
)

type RssFeed struct {
	XMLName xml.Name `xml:"rss"`
	Channel Channel  `xml:"channel"`
}

type Channel struct {
	Title         string `xml:"title"`
	Link          string `xml:"link"`
	Description   string `xml:"description"`
	PubDate       string `xml:"pubDate"`
	LastBuildDate string `xml:"lastBuildDate"`
	Items         []Item `xml:"item"`
}

type Item struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	PubDate     string `xml:"pubDate"`
	Guid        string `xml:"guid"`
}

func rssRouterHandler(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://www.rssboard.org/files/sample-rss-2.xml")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var feed RssFeed
	err = xml.Unmarshal(body, &feed)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	html := "<h1>RSS Feed</h1>"
	html += "<h2>" + feed.Channel.Title + "</h2>"
	html += "<p>" + feed.Channel.Description + "</p>"
	html += "<p><a href=\"/\">Back to Home</a></p>"

	html += "<ul>"
	for _, item := range feed.Channel.Items {
		html += "<li><a href=\"" + item.Link + "\">" + item.Title + "</a></li>"
		html += "<p>" + item.Description + "</p>"
	}
	html += "</ul>"

	w.Write([]byte(html))
}

func HomeRouterHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	fmt.Println(r.Form)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Println("key:", k)
		fmt.Println("val:", strings.Join(v, ""))
	}
	fmt.Fprintf(w, `
		<h1>Welcome to the Home Page!</h1>
		<ul>
			<li><a href="/link1">Page 1</a></li>
			<li><a href="/link2">Page 2</a></li>
			<li><a href="/link3">Page 3</a></li>
			<li><a href="/rss">RSS Feed</a></li>
		</ul>
	`)
}

func PageRouterHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	fmt.Println(r.Form)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Println("key:", k)
		fmt.Println("val:", strings.Join(v, ""))
	}

	switch r.URL.Path {
	case "/link1":
		fmt.Fprintf(w, `
			<h1>Page 1</h1>
			<p>This is Page 1.</p>
			<p> Voluptate voluptate qui labore aliqua cillum cillum eu ipsum dolor ea. Eu magna eiusmod fugiat ut ex elit occaecat irure amet excepteur consequat culpa esse. Proident magna elit et aliquip qui exercitation sit adipisicing ea. Magna quis irure elit nisi consequat cupidatat ea. Non laboris fugiat consectetur proident incididunt. Velit adipisicing duis mollit sit est minim elit nulla cupidatat nulla eu Lorem reprehenderit.</p>
			<p><a href="/">Back to Home</a></p>
		`)
	case "/link2":
		fmt.Fprintf(w, `
			<h1>Page 2</h1>
			<p>This is Page 2.</p>
			<p>))))))</p>
			<p><a href="/">Back to Home</a></p>
		`)
	case "/link3":
		fmt.Fprintf(w, `
			<h1>Page 3</h1>
			<p>This is Page 3.</p>
			<p> Id dolore non in aliquip nisi ea ullamco et magna minim laboris est nisi id. Adipisicing aliqua laboris deserunt elit id proident elit magna consectetur mollit minim. Veniam deserunt eu incididunt eiusmod ut. Eu adipisicing id sint ut magna nisi duis est enim dolore enim. Sunt consequat cupidatat cupidatat qui tempor incididunt laborum esse et fugiat nostrud laboris mollit. Do laboris esse deserunt eiusmod nulla aliquip quis non aliqua incididunt. Eiusmod incididunt adipisicing exercitation dolore.</p>
			<p><a href="/">Back to Home</a></p>
		`)
	default:
		fmt.Fprintf(w, "Not found")
	}
}

func main() {
	http.HandleFunc("/", HomeRouterHandler)
	http.HandleFunc("/link1", PageRouterHandler)
	http.HandleFunc("/link2", PageRouterHandler)
	http.HandleFunc("/link3", PageRouterHandler)
	http.HandleFunc("/rss", rssRouterHandler)

	err := http.ListenAndServe(":9003", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
