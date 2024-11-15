object pdepfoni {
  const property precioPorMB = 0.1
  const property precioFijo = 1
  const property precioPorSegundo = 0.05
}

class Consumo {
  const property fecha = new Date()

  method consumeInternet()
  method costo()
  method consumidoEntre(inicio, fin) = fecha.between(inicio, fin)
}

class ConsumoInternet inherits Consumo {
  const property mb
  override method consumeInternet() = true
  override method costo() = mb * pdepfoni.precioPorMB()
}

class ConsumoLlamada inherits Consumo {
  const property segundos
  override method consumeInternet() = false
  override method costo() = pdepfoni.precioFijo() + ((segundos - 30).max(0)) * pdepfoni.precioPorSegundo()
}

class Pack {
  const vencimiento = new Date()

  method sePuedeUsar(fecha) = fecha < vencimiento

  method puedeCubrir(consumo) = self.sePuedeUsar(consumo.fecha())
  method cubrir(consumo) {}
}

class PackConsumible inherits Pack {
  var consumible

  override method sePuedeUsar(fecha) = super(fecha) && consumible > 0
}

class CreditoDisponible inherits PackConsumible {
  override method puedeCubrir(consumo) = super(consumo) && consumo.costo() <= consumible

  override method cubrir(consumo) {
    if (self.puedeCubrir(consumo)) 
      consumible -= consumo.costo()
  }
}

class MBLibres inherits PackConsumible {
  override method puedeCubrir(consumo) = super(consumo) && consumo.consumeInternet() && consumo.mb() <= consumible

  override method cubrir(consumo) {
    if (self.puedeCubrir(consumo)) 
      consumible -= consumo.mb()
  }
}

class MBLibresPlus inherits MBLibres {
  override method puedeCubrir(consumo) = if (consumible > 0) super(consumo) else consumo.mb() <= 0.1
}

class LlamadasLibres inherits Pack {
  override method puedeCubrir(consumo) = super(consumo) && !(consumo.consumeInternet())
}

class InternetLibreFindes inherits Pack {
  override method puedeCubrir(consumo) = super(consumo) && consumo.consumeInternet() && consumo.fecha().isWeekendDay()
}

class Linea {
  const fechaActual = new Date()
  const property consumos = []
  const property packs = []
  var property deuda = 0
  var property tipo

  method consumosEnPeriodo(inicio, fin) = consumos.filter({consumo => consumo.consumidoEntre(inicio, fin)})
  method gastoPromedio(inicio, fin) = self.consumosEnPeriodo(inicio, fin).sum({consumo => consumo.costo()}) / self.consumosEnPeriodo(inicio, fin).size()
  method gastoUltimoMes() = self.consumosEnPeriodo(fechaActual.minusMonths(1), fechaActual).sum({consumo => consumo.costo()})

  method agregarPack(pack) {
    packs.add(pack)
  }

  method puedeConsumir(consumo) = packs.any({pack => pack.puedeCubrir(consumo)})
  method packsQueCubren(consumo) = packs.filter({pack => pack.puedeCubrir(consumo)})
  method packsVencidos() = packs.filter({pack => !(pack.sePuedeUsar(fechaActual))})

  method realizarConsumo(consumo) {
    if (tipo.permiteRealizarConsumo(self, consumo)) {
      tipo.procesarConsumo(self, consumo)
    }
    else {throw new DomainException()}
  }

  method limpiarPacks() {
    self.packsVencidos().forEach({packVencido => packs.remove(packVencido)})
  }
}

object comun {
  method permiteRealizarConsumo(linea, consumo) = linea.puedeConsumir(consumo)

  method procesarConsumo(linea, consumo) {
    linea.consumos().add(consumo)
    linea.packsQueCubren(consumo).last().cubrir(consumo)
  }
}

object black {
  method permiteRealizarConsumo(linea, consumo) = true

  method procesarConsumo(linea, consumo) {
    if (linea.puedeConsumir(consumo)) {
      linea.consumos().add(consumo)
      linea.packsQueCubren(consumo).last().cubrir(consumo)
    }
    else {
      linea.consumos().add(consumo)
      linea.deuda(linea.deuda() + consumo.costo())
    }
  }
}

object platinum {
  method permiteRealizarConsumo(linea, consumo) = true

  method procesarConsumo(linea, consumo) {
    linea.consumos().add(consumo)
  }
}
