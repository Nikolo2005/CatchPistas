#!/bin/bash

#Este script se ejecuta en 22.04.1-Ubuntu

# Función para imprimir el logo en colores
# Definición de colores

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_text() {

    echo -e "\e[1;36m  ___  _   _ ___ _____  _    ____    ____ ___ ____ _____  _    ____  \e[0m"  
    echo -e "\e[1;36m / _ \| | | |_ _|_   _|/ \  |  _ \  |  _ \_ _/ ___|_   _|/ \  / ___| \e[0m"
    echo -e "\e[1;36m| | | | | | || |  | | / _ \ | |_) | | |_) | |\___ \ | | / _ \ \___ \ \e[0m"   
    echo -e "\e[1;36m| |_| | |_| || |  | |/ ___ \|  _ <  |  __/| | ___) || |/ ___ \ ___) |\e[0m"
    echo -e "\e[1;36m \__\_\____/|___| |_/_/   \_\_| \_\ |_|  |___|____/ |_/_/   \_\____/ \e[0m"
    echo 
    echo -e "\e[1;4mCreador: Nicolas\e[0m"
    echo 
}



# Imprimir el logo y los créditos
print_text


xdg-open https://www.rgcc.es

sleep 2


# Ruta al archivo de cookies de Firefox (cambia esto según tu sistema operativo y usuario)
cp "$HOME/snap/firefox/common/.mozilla/firefox/00pc9qor.default/cookies.sqlite" "$HOME/Documentos/cookie_file.tmp"
cookie_file="$HOME/Documentos/cookie_file.tmp"


# Consulta SQL para obtener las cookies necesarias excepto mod_auth_openidc_session
query="SELECT name, value, host, path FROM moz_cookies WHERE \
(host='rgcc.es' AND name IN ('AWSALB', 'AWSALBCORS', 'CookieConsent', \
'wpui', 'wordpress_logged_in_5be150c365cad0d74f1123dbe3a42040', 'wploggedin'))"

# Ejecuta la consulta SQL y obtén las cookies
cookies=$(sqlite3 "$cookie_file" "$query")

# Construye la cadena de cookies
cookie_string=""
while IFS="|" read -r name value host path; do
    cookie_string+="--cookie '$name=$value;'"
done <<< "$cookies"


# Solicita al usuario que ingrese manualmente la cookie mod_auth_openidc_session
read -p "Introduce la cookie mod_auth_openidc_session: " mod_auth_openidc_session

# Verifica si la cookie mod_auth_openidc_session no está vacía
if [ -z "$mod_auth_openidc_session" ]; then
    echo -e "${RED}La cookie mod_auth_openidc_session no puede estar vacía.${NC}"
    exit 1
fi


# Solicitud del carnet a utilizar
echo -e "${YELLOW}Introduce el carnet${NC}"
read -r numSocio

# Solicitud del código de recurso deportivo a utilizar
echo -e "${YELLOW}Selecciona el código de recurso deportivo:${NC}"
echo "1. Pista de Padel 1 (AF000210)"
echo "2. Pista de Padel 2 (AF000940)"
echo "3. Pista de Padel 3 (AF000950)"
echo "4. Pista de Padel 4 (AF000960)"
echo "5. Pista de Padel 5 (AF000970)"
echo "6. Pista de Padel 6 (AF000980)"
echo -e "${YELLOW}Pon un numero del 1 al 6${NC}"
read -r OPCION

# Validación de la opción seleccionada
case "$OPCION" in
  1) codRecurso="AF000210";;
  2) codRecurso="AF000940";;
  3) codRecurso="AF000950";;
  4) codRecurso="AF000960";;
  5) codRecurso="AF000970";;
  6) codRecurso="AF000980";;
  *) echo -e "${RED}Opción inválida. Por favor, selecciona una opción del 1 al 6.${NC}"
     exit 1;;
esac

# Solicitud de hora
echo -e "${YELLOW}Introduce la hora en formato HH por ejemplo 14${NC}"
read -r hora

# Verifica si la cookie mod_auth_openidc_session no está vacía
if [ -z "$mod_auth_openidc_session" ]; then
    echo -e "${RED}La cookie mod_auth_openidc_session no puede estar vacía.${NC}"
    exit 1
fi

# Suma 1 día al día del sistema
date=$(date '+%Y-%m-%d' --date='+1 day')

echo -e "${YELLOW}Pulsa ENTER para coger la pista, este programa se ejecutará hasta que la pista se haya cogido${NC}"
read -r

while true; do
    # Realiza la solicitud web con todas las cookies
    response=$(curl -s -X POST "https://www.rgcc.es/rgcc-services/FuncionesSW/CreateReservation" \
        -H "Accept: application/json, text/plain, */*" \
        -H "Accept-Language: es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "X-RGCC-User: $numSocio" \
        -H "Origin: https://www.rgcc.es" \
        -H "Referer: https://www.rgcc.es/instalaciones/reserva/?facility=GR-0002&date=$date" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "TE: trailers" \
        -H "Content-Type: application/json" \
        -d "{\"sociosArray\":[\"$numSocio\"],\"codRecursoDeportivo\":\"$codRecurso\",\"startTime\":\"$date"T"$hora:15:00+02:00\",\"intervalNumber\":1,\"numReserva\":[1]}" \
        $cookie_string --cookie "mod_auth_openidc_session=$mod_auth_openidc_session")

    # Imprimir la respuesta
    echo -e "${GREEN}Respuesta del servidor:${NC} $response"

    # Verificar si la respuesta contiene el mensaje de detención
    if [[ $response == *"Reserva realizada"* ]]; then
        echo -e "${GREEN}Se encontró el mensaje de detención. Deteniendo el bucle.${NC}"
        break
    fi
done

