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
  override method costo() = pdepfoni.precioFijo() + (segundos - 30) * pdepfoni.precioPorSegundo()
}

class Pack {
  const vencimiento = new Date()

  method vencidoPara(consumo) = consumo.fecha() > vencimiento
  method puedeCubrir(consumo) = !(self.vencidoPara(consumo))
}

class PackConsumible inherits Pack {
  method gastar(consumo)
}

class CreditoDisponible inherits PackConsumible {
  var credito

  override method puedeCubrir(consumo) {
    self.gastar(consumo)
    return super(consumo) && consumo.costo() <= credito
  }

  override method gastar(consumo) {
    if (super(consumo) && consumo.costo() <= credito) 
      credito -= consumo.costo()
  }
}

class MBLibres inherits PackConsumible {
  var mbLibres
  override method puedeCubrir(consumo) {
    self.gastar(consumo)
    return super(consumo) && consumo.consumeInternet() && consumo.mb() <= mbLibres
  }

  override method gastar(consumo) {
    if (super(consumo) && consumo.consumeInternet() && consumo.mb() <= mbLibres) 
      mbLibres -= consumo.mb()
  }
}

class LlamadasLibres inherits Pack {
  override method puedeCubrir(consumo) = super(consumo) && !(consumo.consumeInternet())
}

class InternetLibreFindes inherits Pack {
  override method puedeCubrir(consumo) = super(consumo) && consumo.consumeInternet() && consumo.fecha().isWeekendDay()
}

class Linea {
  const fechaActual = new Date()
  const consumos = []
  const packs = []

  method consumosEnPeriodo(inicio, fin) = consumos.filter({consumo => consumo.consumidoEntre(inicio, fin)})
  method gastoPromedio(inicio, fin) = self.consumosEnPeriodo(inicio, fin).sum({consumo => consumo.costo()}) / self.consumosEnPeriodo(inicio, fin).size()
  method gastoUltimoMes() = self.consumosEnPeriodo(fechaActual.minusMonths(1), fechaActual).sum({consumo => consumo.costo()})

  method agregarPack(pack) {
    packs.add(pack)
  }

  method puedeConsumir(consumo) = packs.any({pack => pack.puedeCubrir(consumo)})
  method packsQueCubren(consumo) = packs.filter({pack => pack.puedeCubrir(consumo)})

  method realizarConsumo(consumo) {
    if (self.puedeConsumir(consumo)) {
      consumos.add(consumo)
      packs.remove(self.packsQueCubren(consumo).last())
    }
    else {throw new DomainException()}
  }
}
