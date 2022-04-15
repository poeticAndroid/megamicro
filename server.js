const http = require("http"),
  https = require("https"),
  fs = require("fs"),
  path = require("path")

const hostname = "127.0.0.1"
const port = process.env.PORT

let updated = [],
  notfound = []

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
  if (notfound.includes(filename)) {
    res.statusCode = 404
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    res.end("<h1> still nothing here ")
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
  fs.readFile(filename, (err, data) => {
    if (err || !updated.includes(filename)) {
      fs.mkdirSync(path.dirname(filename), { recursive: true })
      fs.open(filename, "w", (err, fd) => {
        if (err) {
          res.setHeader("Content-Type", "text/html; charset=utf-8")
          res.end("<h1> could not write file :( ")
          return
        }
        https.get("https://raw.githubusercontent.com/poeticAndroid/megamicro/master/" + filename.slice(2), (resp) => {
          if (resp.statusCode === 200) {
            updated.push(filename)
            resp.on("data", (d) => {
              fs.writeSync(fd, d, (err) => console.error)
              res.write(d)
            })
            resp.on("end", (err) => {
              fs.closeSync(fd, (err) => console.error)
              res.end()
            })
          } else {
            notfound.push(filename)
            res.statusCode = 404
            res.setHeader("Content-Type", "text/html; charset=utf-8")
            res.end("<h1>nothing here")
            fs.closeSync(fd, (err) => console.error)
            fs.unlinkSync(filename)
            filename = path.dirname(filename)
            while (filename.length > 2) {
              try {
                fs.rmdirSync(filename)
              } catch (error) {
                //  ¯\_(ツ)_/¯ 
              }
              filename = path.dirname(filename)
            }
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
