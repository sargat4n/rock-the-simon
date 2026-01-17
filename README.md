# Rock the Simon

Plugin para Counter-Strike 1.6 (AMX Mod X). Permite que los prisioneros (terroristas) inicien una votación para elegir un guardia/simón y pasarlo al equipo de prisioneros si se alcanza un consenso (un 80% de los votos).

## Estado del plugin

- Versión: 0.1.0
- Autor: Sargatan
	- Steam: https://steamcommunity.com/id/sargatan

## Características

- Solo los prisioneros pueden iniciar el proceso.
- Requiere al menos 1 guardia en el servidor.
- Todos los prisioneros deben escribir el comando para iniciar la votación.
- Requiere 80% de consenso para cambiar al guardia.

## Estructura de archivos

- scripting/rock_the_simon.sma: código fuente del plugin.
- configs/rock_the_simon.cfg: configuración básica.

## Requisitos

- Counter-Strike 1.6
- AMX Mod X 1.8.2 o superior
- Módulo cstrike habilitado

## Entorno de compilación y pruebas

- Compilado con AMX Mod X 1.10-git5474
- Probado con Metamod-P 1.21p38

## Instalación

1. Compilar el archivo scripting/rock_the_simon.sma con el compilador de AMX Mod X.
2. Copiar el archivo rock_the_simon.amxx a la carpeta plugins del servidor.
3. Agregar rock_the_simon.amxx al archivo configs/plugins.ini del servidor.
4. Copiar configs/rock_the_simon.cfg al directorio configs del servidor.

## Configuración

Archivo: configs/rock_the_simon.cfg

- rts_enabled 1
	- 1 = habilitado
	- 0 = deshabilitado

## Comandos

Comandos disponibles para prisioneros:

- rts
- rockthesimon

## Flujo de juego

1. Un prisionero escribe rts o rockthesimon.
2. El plugin registra su voto de inicio.
3. Cuando todos los prisioneros han escrito el comando, se inicia la votación.
4. La votación muestra un menú con los guardias disponibles.
5. Cada prisionero vota por un guardia/simón.
6. Se calcula el consenso. Solo se cambia al guardia si el 80% de los prisioneros votó al mismo guardia.
7. Si no se alcanza el 80%, no hay cambio de equipo.

## Detalles técnicos

- El voto dura 10 segundos.
- La votación solo puede hacerse una vez por ronda.
- En inicio de ronda se limpia el estado interno.

## Solución de problemas

- Si el comando no funciona, revisar que rts_enabled esté en 1.
- Verificar que haya al menos un guardia en el servidor.
- Asegurarse de tener cstrike habilitado en modules.ini.

## Personalización

- Cambiar textos o colores en scripting/rock_the_simon.sma.
- Ajustar la duración de votación modificando VOTE_TIME.
- Ajustar el porcentaje de consenso en la lógica de finish_vote.
