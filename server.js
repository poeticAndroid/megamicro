const http = require("http"),
  https = require("https"),
  fs = require("fs")

const hostname = "127.0.0.1"
const port = process.env.PORT

let deleted = [],
  notfound = []

const server = http.createServer((req, res) => {
  res.setHeader("Cache-Control", "max-age=4096")
  let path = "." + req.url
  if (path.slice(-1) === "/") {
    path += "index.html"
  }
  if (path.slice(0, 3) === "./.") {
    res.statusCode = 404
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    res.end("<h1> nope ")
    return
  }
  if (notfound.includes(path)) {
    res.statusCode = 404
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    res.end("<h1> still nothing here ")
    return
  }
  let ext = path.slice(path.lastIndexOf("."))
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
  if (!deleted.includes(path)) {
    deleted.push(path)
    fs.unlinkSync(path)
  }
  fs.readFile(path, (err, data) => {
    if (err) {
      fs.open(path, "w", (err, fd) => {
        https.get("https://raw.githubusercontent.com/poeticAndroid/megamicro/master/" + path.slice(2), (resp) => {
          if (resp.statusCode === 200) {
            resp.on("data", (d) => {
              fs.writeSync(fd, d, (err) => console.error)
              res.write(d)
            })
            resp.on("end", (err) => {
              fs.closeSync(fd, (err) => console.error)
              res.end()
            })
          } else {
            notfound.push(path)
            fs.closeSync(fd, (err) => console.error)
            fs.unlinkSync(path)
            res.statusCode = 404
            res.setHeader("Content-Type", "text/html; charset=utf-8")
            res.end("<h1>nothing here")
          }
        })
      })
    } else {
      res.statusCode = 200
      res.end(data)
    }
  })
})

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})
