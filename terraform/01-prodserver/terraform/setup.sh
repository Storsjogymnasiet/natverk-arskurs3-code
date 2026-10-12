#!/bin/bash
# setup.sh — frågar efter dina uppgifter och skriver terraform.tfvars
# Kör:  ./setup.sh

set -e
cd "$(dirname "$0")"

# Gör ett värde säkert att skriva inom "..." i terraform.tfvars
hcl() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\${/$${/g' -e 's/%{/%%{/g'; }

echo "=============================="
echo " Prod-server — inställningar"
echo "=============================="
echo ""

if [ -f terraform.tfvars ]; then
    read -rp "terraform.tfvars finns redan. Skriva över? [j/N] " svar
    [[ $svar =~ ^[jJ]$ ]] || { echo "Avbryter."; exit 0; }
fi

# AD-användarnamn
while true; do
    read -rp "Ditt AD-användarnamn (t.ex. itjoab01): " elev
    elev=${elev,,}
    [[ $elev =~ ^[a-z][a-z0-9-]{1,20}$ ]] && break
    echo "  Bara små bokstäver a-z, siffror och bindestreck."
done

# API-token
echo ""
echo "API-token: skapa den i Proxmox → Datacenter → Permissions → API Tokens → Add"
echo "  User: $elev@valhalla   Token ID: terraform   Avmarkera \"Privilege Separation\""
while true; do
    read -rsp "Klistra in Secret (syns inte när du skriver): " secret
    echo ""
    [[ $secret =~ ^[0-9a-f-]{36}$ ]] && break
    echo "  Ser inte ut som en token (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx). Försök igen."
done

# Nod
echo ""
echo "Vilken nod ska servern ligga på?"
select nod in asgard-midgard003 asgard-midgard004; do
    [ -n "$nod" ] && break
done

# IP-adress
echo ""
while true; do
    read -rp "Din Prod-IP från Excel i Teams (t.ex. 192.168.47.150): " ip
    [[ $ip =~ ^192\.168\.47\.([0-9]{1,3})$ ]] && (( BASH_REMATCH[1] >= 2 && BASH_REMATCH[1] <= 254 )) && break
    echo "  Ange en adress i 192.168.47.0/24, utan /24."
done

# Konto på servern
echo ""
read -rp "Användarnamn på servern [$elev]: " username
username=${username:-$elev}
while true; do
    read -rsp "Lösenord på servern (för SSH, sudo och Proxmox-konsolen): " password
    echo ""
    read -rsp "Samma lösenord igen: " password2
    echo ""
    [ "$password" = "$password2" ] && [ ${#password} -ge 8 ] && break
    echo "  Lösenorden matchar inte eller är kortare än 8 tecken."
done

# Skriv terraform.tfvars (bara du kan läsa den)
umask 077
cat > terraform.tfvars <<EOF
# Skapad av setup.sh $(date '+%Y-%m-%d %H:%M'). Innehåller hemligheter – dela aldrig.
proxmox_api_token = "$(hcl "$elev@valhalla!terraform=$secret")"
proxmox_node      = "$nod"

elev     = "$(hcl "$elev")"
ip       = "$(hcl "$ip")"
username = "$(hcl "$username")"
password = "$(hcl "$password")"
EOF

echo ""
echo "Klart! terraform.tfvars är skapad."
echo "Servern blir: prod-$elev på $nod med IP $ip"
echo ""
read -rp "Köra terraform init och terraform plan nu? [J/n] " svar
if [[ ! $svar =~ ^[nN]$ ]]; then
    terraform init -input=false
    terraform plan
    echo ""
    echo "Ser planen rätt ut? Kör:  terraform apply"
fi
