const http = require("http"),
  https = require("https"),
  fs = require("fs"),
  path = require("path")

const hostname = "0.0.0.0"
const port = process.env.PORT

const server = http.createServer((req, res) => {
  res.setHeader("Cache-Control", "max-age=4096")
  let filename = "." + req.url
  if (filename.slice(-1) === "/") {
    filename += "index.html"
  }
  if (filename.slice(0, 3) === "./.") {
    res.statusCode = 404
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    res.end("<h1> nope ")
    return
  }
  let ext = filename.slice(filename.lastIndexOf("."))
  switch (ext) {
    case ".html":
      res.setHeader("Content-Type", "text/html; charset=utf-8")
      break
    case ".css":
      res.setHeader("Content-Type", "text/css; charset=utf-8")
      break
    case ".js":
      res.setHeader("Content-Type", "application/javascript; charset=utf-8")
      break
    default:
      res.setHeader("Content-Type", "text/plain; charset=utf-8")
  }
  console.log("Reading", filename)
  fs.readFile(filename, (err, data) => {
    if (err) {
      res.statusCode = 404
      res.setHeader("Content-Type", "text/html; charset=utf-8")
      res.end("<h1>nothing here")
    } else {
      res.statusCode = 200
      res.end(data)
    }
  })
})

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})
