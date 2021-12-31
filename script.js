(() => {
  let cpu
  let ram = new WebAssembly.Memory({ initial: 1 })

  async function init() {
    await loadCPU("cypu.wasm", { pcb: { ram: ram } })
    render()
  } init()

  async function loadCPU(path, imports) {
    let bin = await (await fetch(path)).arrayBuffer()
    await WebAssembly.instantiate(bin, imports).then(wasm => {
      cpu = wasm.instance.exports
    })
  }

  function render(t) {
    let opcode = cpu.run(1)
    // console.log(cpu.getReg(0), opcode)
    requestAnimationFrame(render)
  }
})()