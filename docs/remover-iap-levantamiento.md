# Levantamiento: Remocion de In-App Purchases - Prey iOS

## Resumen Ejecutivo

| Categoria | Cantidad |
|-----------|----------|
| Archivos a eliminar | 4 |
| Archivos a modificar | 9 |
| Configuracion Xcode | 1 capability |
| Producto IAP | 1 (non-renewing subscription) |
| **Riesgo App Store** | **Bajo** |

---

## 1. Arquitectura Actual de IAP

### Producto Configurado
- **Product ID**: `1year_starter_plan_non_renewing_full`
- **Tipo**: Non-renewing subscription (1 año)
- **Framework**: StoreKit 1

### Flujo de Compra Actual
```
Usuario en Settings
    ↓
Toca "Upgrade to Pro"
    ↓
PurchasesVC muestra precio
    ↓
Usuario toca "Comprar"
    ↓
PreyStoreManager → SKPaymentQueue
    ↓
App Store procesa pago
    ↓
Receipt enviado a backend (/subscriptions/receipt)
    ↓
Backend valida → isPro = true
    ↓
GrettingsProVC muestra confirmacion
```

---

## 2. Archivos a Eliminar

| Archivo | Ubicacion | Proposito |
|---------|-----------|-----------|
| `PreyStoreManager.swift` | `/Prey/Classes/` | Manager principal de StoreKit, maneja transacciones |
| `PreyStoreProduct.swift` | `/Prey/Classes/` | Validacion de recibos con backend |
| `PurchasesVC.swift` | `/Prey/Classes/` | Pantalla de compra con boton y precio |
| `GrettingsProVC.swift` | `/Prey/Classes/` | Pantalla de confirmacion post-compra |

---

## 3. Archivos a Modificar

### 3.1 Constants.swift
**Ubicacion**: `/Prey/Classes/Constants.swift`

| Linea | Cambio |
|-------|--------|
| 45 | Eliminar: `public let subscription1Year = "1year_starter_plan_non_renewing_full"` |

---

### 3.2 PreyProtocol.swift
**Ubicacion**: `/Prey/Classes/PreyProtocol.swift`

| Linea | Cambio |
|-------|--------|
| 135 | Eliminar: `public let subscriptionEndpoint : String = "/subscriptions/receipt"` |

---

### 3.3 PreyHTTPResponse.swift
**Ubicacion**: `/Prey/Classes/PreyHTTPResponse.swift`

| Linea | Cambio |
|-------|--------|
| 14 | Eliminar `subscriptionReceipt` del enum `RequestType` |
| 65-66 | Eliminar case `.subscriptionReceipt:` y llamada a `checkSubscriptionReceipt` |
| 319-337 | Eliminar funcion `checkSubscriptionReceipt()` completa |

---

### 3.4 SettingsVC.swift
**Ubicacion**: `/Prey/Classes/SettingsVC.swift`

| Linea | Cambio |
|-------|--------|
| 20 | Eliminar `upgradeToPro` del enum `SectionInformation` |
| 98-100 | Eliminar bloque que llama a `PreyStoreManager.sharedInstance.requestProductData()` |
| 145-148 | Eliminar logica condicional de `isPro` para ocultar celda (ya no sera necesaria) |
| 245-246 | Eliminar case `SectionInformation.upgradeToPro` en `configCellForInformationSection` |
| 370-372 | Eliminar case de navegacion a `StoryboardIdVC.purchases` |

**Cambio minimo alternativo** (si se quiere hacer gradual sin eliminar codigo):
```swift
// Linea 145-148: Cambiar de:
numberRows = SectionInformation.numberSectionInformation.rawValue
if PreyConfig.sharedInstance.isPro {
    numberRows -= 1
}

// A:
numberRows = SectionInformation.numberSectionInformation.rawValue
numberRows -= 1  // Siempre ocultar "Upgrade to Pro"
```

---

### 3.5 PreyConfig.swift
**Ubicacion**: `/Prey/Classes/PreyConfig.swift`

| Decision | Accion |
|----------|--------|
| Mantener usuarios Pro existentes | No cambiar nada, `isPro` se mantiene en UserDefaults |
| Todos son Pro | Forzar `isPro = true` o eliminar toda logica condicional |
| Nadie es Pro local | Eliminar propiedad `isPro` completamente |

**Nota importante**: El backend ya envia `pro_account` en el login (linea 137-145 de PreyHTTPResponse.swift), por lo que `isPro` tambien se actualiza desde el servidor. Si se decide mantener la propiedad, seguira funcionando con el valor del backend.

---

### 3.6 PreyStoryBoard.storyboard
**Ubicacion**: `/Prey/Base.lproj/PreyStoryBoard.storyboard`

| Elemento | Linea Storyboard | Storyboard ID | Accion |
|----------|------------------|---------------|--------|
| PurchasesVC scene | 1083-1145 | `purchases` | Eliminar escena completa |
| GrettingsProVC scene | 1347-1412 | `grettings` | Eliminar escena completa |

---

### 3.7 Localizable.strings
**Ubicacion**: `/Prey/Localizable.strings/`

**Idiomas afectados**: `en.lproj`, `es.lproj`

Strings a eliminar:

| Linea (en.lproj) | String |
|------------------|--------|
| 21 | `"FULL PROTECTION FOR YOUR DEVICES"` |
| 23 | `"100 reports per device \nUltra-fast frecuency..."` |
| 25 | `"Personal Plan, 1 year"` |
| 171 | `"Upgrade to Pro"` |
| 205 | `"Thanks for your support..."` |
| 207 | `"Congrats,\nyou're now Pro"` |
| 233 | `"Canceled transaction, please try again."` |

---

### 3.8 PreyRestTests.swift
**Ubicacion**: `/PreyTests/PreyRestTests.swift`

| Linea | Cambio |
|-------|--------|
| 176-206 | Eliminar funcion `testRest07TransactionInAppPurchase()` completa |

---

### 3.9 StoryboardIdVC enum en Constants.swift
**Ubicacion**: `/Prey/Classes/Constants.swift`

| Linea | Cambio |
|-------|--------|
| 18-19 | Eliminar `purchases` y `grettings` del enum `StoryboardIdVC` |

**Actual**:
```swift
enum StoryboardIdVC: String {
    case PreyStoryBoard, alert, navigation, home, currentLocation, purchases, settings, grettings, homeWeb, rename
}
```

**Nuevo**:
```swift
enum StoryboardIdVC: String {
    case PreyStoryBoard, alert, navigation, home, currentLocation, settings, homeWeb, rename
}
```

---

## 4. Configuracion de Xcode

### 4.1 Capability In-App Purchase
**Ubicacion**: `Prey.xcodeproj/project.pbxproj`

**Desactivar desde Xcode**:
1. Abrir proyecto en Xcode
2. Seleccionar target "Prey"
3. Tab "Signing & Capabilities"
4. Eliminar "In-App Purchase" capability (click en "x")

---

## 5. App Store Connect

### 5.1 Producto IAP
| Accion | Detalle |
|--------|---------|
| Marcar como "Removed from Sale" | NO eliminar completamente, solo quitar de venta |
| Mantener historial | Apple recomienda conservar para reportes |

### 5.2 Metadata de la App
- [ ] Revisar descripcion de la app (eliminar menciones de compras)
- [ ] Revisar screenshots (eliminar capturas de pantalla de compra)
- [ ] Actualizar "What's New" en nueva version

---

## 6. Consideraciones App Store

### No hay riesgo de rechazo porque:
- No existe obligacion de tener IAP
- La app sigue funcionando (servicio de tracking)
- El modelo de negocio puede ser web-based
- Es un proceso comun y aceptado

### Requisitos para aprobacion:
- [ ] No eliminar features prometidas sin alternativa
- [ ] Manejar adecuadamente usuarios que ya compraron
- [ ] Actualizar metadata de la app

---

## 7. Manejo de Usuarios Pro Existentes

### Opcion A: Mantener privilegios (Recomendada)
- Conservar `isPro` en `PreyConfig`
- Usuarios que pagaron mantienen su status
- **Pros**: Respeta compra anterior
- **Contras**: Codigo legacy permanece

### Opcion B: Todos son Pro
- Forzar `isPro = true` para todos
- Eliminar toda logica condicional
- **Pros**: Simplifica codigo
- **Contras**: Puede requerir cambios en backend

### Opcion C: Nadie es Pro localmente
- Status Pro se maneja 100% desde backend/panel web
- El backend ya envia `pro_account` en login
- **Pros**: Fuente unica de verdad
- **Contras**: Requiere verificar soporte del backend

---

## 8. Flujo de Trabajo Recomendado

```
┌─────────────────────────────────────────────────────────┐
│ FASE 1: App Store Connect                               │
├─────────────────────────────────────────────────────────┤
│ □ Marcar IAP como "Removed from Sale"                   │
│ □ Actualizar descripcion de la app                      │
│ □ Actualizar screenshots si es necesario                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 2: Codigo - Cambio Minimo (Opcional/Inmediato)     │
├─────────────────────────────────────────────────────────┤
│ □ Ocultar celda "Upgrade to Pro" en SettingsVC          │
│ □ Eliminar llamada a requestProductData()               │
│ □ Probar que la app funciona correctamente              │
│ □ Submit version intermedia                             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 3: Codigo - Limpieza Completa                      │
├─────────────────────────────────────────────────────────┤
│ □ Eliminar archivos IAP (4 archivos)                    │
│ □ Modificar archivos dependientes (9 archivos)          │
│ □ Decidir manejo de usuarios Pro existentes             │
│ □ Eliminar strings de localizacion                      │
│ □ Eliminar escenas del Storyboard                       │
│ □ Actualizar tests                                      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 4: Xcode                                           │
├─────────────────────────────────────────────────────────┤
│ □ Desactivar capability de In-App Purchase              │
│ □ Verificar que no hay errores de compilacion           │
│ □ Verificar que no hay warnings de StoreKit             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ FASE 5: Testing y Release                               │
├─────────────────────────────────────────────────────────┤
│ □ Probar app completa                                   │
│ □ Verificar que usuarios Pro existentes mantienen status│
│ □ Submit nueva version con notas explicativas           │
└─────────────────────────────────────────────────────────┘
```

---

## 9. Notas de Version Sugeridas

> **What's New:**
> - Las suscripciones ahora se gestionan directamente desde el panel web en preyproject.com
> - Mejoras de rendimiento y estabilidad

---

## 10. Checklist Final

### Pre-release
- [ ] IAP marcado como "Removed from Sale" en App Store Connect
- [ ] Codigo modificado segun plan elegido
- [ ] Capability desactivada en Xcode
- [ ] Tests actualizados y pasando
- [ ] App probada en dispositivo fisico
- [ ] Usuarios Pro existentes verificados

### Post-release
- [ ] Monitorear reviews por confusion de usuarios
- [ ] Verificar que no hay errores en Crashlytics/Analytics
- [ ] Actualizar documentacion interna

---

## Anexo A: Comportamiento si Solo se Quita el Producto

Si se quita el producto del App Store pero NO se modifica el codigo:

| Elemento | Comportamiento |
|----------|---------------|
| Celda "Upgrade to Pro" | Sigue visible |
| Pantalla de compra | Se puede abrir |
| Boton de compra | Sin precio (texto vacio) |
| Al tocar comprar | Error: "Canceled transaction, please try again" |
| **Experiencia** | **Confusa y rota** |

**Conclusion**: Se requiere al menos el cambio minimo de ocultar la celda.

---

## Anexo B: Archivos que Usan `isPro`

Archivos donde se referencia `isPro` y podrian necesitar revision:

| Archivo | Uso |
|---------|-----|
| `PreyConfig.swift` | Propiedad principal, guardado en UserDefaults |
| `PreyHTTPResponse.swift:145` | Se actualiza desde respuesta de login (`pro_account`) |
| `SettingsVC.swift:146` | Condicional para mostrar/ocultar celda |
| `PurchasesVC.swift:103` | Se marca `true` despues de compra exitosa |
| `PreyDeployment.swift:152` | Se marca durante setup de deployment |

---

## Anexo C: Dependencias de Imports

El archivo `PreyStoreManager.swift` importa `StoreKit`. Al eliminarlo:
- Se elimina la unica dependencia directa de StoreKit para compras
- `PreyRateUs.swift` tambien importa StoreKit pero solo para `SKStoreReviewController` (rate app), no para compras

---

*Documento generado el 2026-01-19*
*Proyecto: Prey iOS Client*
