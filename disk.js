function load(file, bin = false) {
  let src = localStorage.getItem(file)
  console.log("load", file, src)
  let out = ""
  if (bin) out = new Uint8Array(src.length / 2)
  for (let i = 0; i < src.length; i += 2) {
    if (bin) out[i / 2] = parseInt(src.slice(i, i + 2), 16)
    else out += String.fromCharCode(parseInt(src.slice(i, i + 2), 16))
  }
  return out
}

function save(file, data) {
  let src = ""
  for (let i = 0; i < data.length; i++) {
    if (typeof data === "string") src += ("00" + data.charCodeAt(i).toString(16)).slice(-2)
    else src += ("00" + data[i].toString(16)).slice(-2)
  }
  console.log("save", file, src)
  localStorage.setItem(file, src)
  localStorage.setItem("date:" + file, Date.now())
}

function diskPath(path) {
  let dirs = path.split("/")
  let valid = []
  if (!dirs[dirs.length - 1]) dirs.pop()
  for (let dir of dirs) {
    if (dir === ".") {
    } else if (dir === "..") {
      valid.pop()
    } else if (dir.includes(":")) {
      valid = []
    } else if (dir) {
      let name = (dir.replaceAll(" ", "_") + ".").split(".")
      valid.push(name[0].toLowerCase().slice(0, 8) + ".".slice(0, name[1].length) + name[1].toLowerCase().slice(0, 3))
    } else {
      valid = []
    }
  }
  return "/" + valid.join("/")
}

function dirname(path) {
  if (path.includes("/")) return path.slice(0, path.lastIndexOf("/"))
  return path
}