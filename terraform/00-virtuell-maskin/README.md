# Ubuntu-server i VirtualBox med Terraform

Skapa, konfigurera och riva virtuella Ubuntu Server-maskiner i **Oracle VirtualBox**
med **Terraform** – utan att klicka runt i VirtualBox-gränssnittet.

Med ett kommando (`terraform apply`) får du:

- en eller flera Ubuntu 24.04 LTS-servrar
- bryggade till ditt nätverk (egen IP via DHCP, internet)
- med hostname och användarkonton satta åt dig
- borttagna igen med `terraform destroy`

> Skrivet för **Linux** (utvecklat på Linux Mint / VirtualBox 7.2). Fungerar även
> på Windows/macOS men förberedelserna nedan är Linux-specifika.

---

## Snabbstart

```bash
git clone <repo-url>
cd <repo-mapp>

# 1. redigera dina inställningar
$EDITOR terraform.tfvars

# 2. kör
terraform init
terraform apply
```

Behöver du installera Terraform och sätta upp nätverket först – se **Förberedelser**.

---

## 1. Vad är Terraform?

Terraform är ett verktyg för **Infrastructure as Code (IaC)**. Istället för att
manuellt skapa servrar, nätverk och brandväggar beskriver du hur allt ska se ut i
textfiler (`.tf`). Terraform jämför sedan din beskrivning med verkligheten och
gör bara de ändringar som behövs.

| Kommando            | Vad det gör                                              |
|---------------------|---------------------------------------------------------|
| `terraform init`    | Laddar ner de "providers" som behövs (här: VirtualBox)  |
| `terraform plan`    | Visar vad som kommer att skapas/ändras/tas bort         |
| `terraform apply`   | Utför ändringarna                                        |
| `terraform destroy` | Tar bort allt som Terraform har skapat                  |

En **provider** är en plugin som låter Terraform prata med ett visst system
(AWS, Azure, VirtualBox, ...). Det finns ingen officiell VirtualBox-provider, så
projektet använder community-providern
[`shekeriev/virtualbox`](https://registry.terraform.io/providers/shekeriev/virtualbox/latest)
(en underhållen kopia av den äldre `terra-farm/virtualbox`).

---

## 2. Så här fungerar projektet

```
                 terraform apply
                        │
                        ▼
   ┌─────────────────────────────────────────────┐
   │ 1. Laddar ner Ubuntu 24.04 "Vagrant-box"     │  (~650 MB, cachas i
   │    (en .box = tar-arkiv med disk + OVF)      │   ~/.terraform/virtualbox/gold)
   ├─────────────────────────────────────────────┤
   │ 2. Importerar den som en VM i VirtualBox     │
   ├─────────────────────────────────────────────┤
   │ 3. Ett bryggat nätverkskort (eth0 i gästen)  │  → hämtar IP från ditt nät
   │                                             │     via DHCP, har internet
   ├─────────────────────────────────────────────┤
   │ 4. Startar VM:en och väntar tills kortet     │
   │    fått en IP-adress                         │
   ├─────────────────────────────────────────────┤
   │ 5. Loggar in via SSH och sätter hostname +   │
   │    skapar användarna du angett i users       │
   ├─────────────────────────────────────────────┤
   │ (upprepas för varje VM när vm_count > 1)     │
   └─────────────────────────────────────────────┘
```

**Bridged-läge** betyder att VM:ens nätverkskort kopplas rakt in på samma fysiska
nät som din dator sitter på. VM:en blir en "riktig" maskin på nätet: den hämtar en
IP från samma DHCP-server (din router), har internet, och kan nås från din dator.
Ingen extra konfiguration – men IP-adressen bestäms av nätet, inte av dig.

### Filer

| Fil                   | Innehåll                                                  |
|-----------------------|----------------------------------------------------------|
| `terraform.tfvars`    | **Dina inställningar** (antal VM:ar, hostname, användare) |
| `main.tf`             | VM:arna, nätverkskortet och provisioneringen             |
| `variables.tf`        | Definierar vilka inställningar som finns + standardvärden |
| `outputs.tf`          | Vad som skrivs ut efter `apply` (IP:er, ssh-kommandon)   |
| `.terraform.lock.hcl` | Låser providerns version                                 |

> **Inloggning:** Ubuntu-boxen har användaren **`vagrant`** med lösenordet
> **`vagrant`** och `sudo` utan lösenord. Det är standard för Vagrant-boxar och
> helt ok i labbmiljö – men byt förstås lösenord på en riktig server.

---

## 3. Förberedelser (en gång per dator)

**a) Installera Terraform.** På Linux:

```bash
cd /tmp
curl -fsSLO https://releases.hashicorp.com/terraform/1.16.1/terraform_1.16.1_linux_amd64.zip
unzip -o terraform_1.16.1_linux_amd64.zip
sudo install -m 0755 terraform /usr/local/bin/terraform
terraform version
```

Andra operativsystem: <https://developer.hashicorp.com/terraform/install>

**b) Installera VirtualBox** (7.x) och se till att du är med i gruppen `vboxusers`
(krävs för bridged-nätverk):

```bash
groups | grep -q vboxusers || sudo usermod -aG vboxusers "$USER"
```

Lade kommandot till dig? **Logga ut och in** (eller starta om).

---

## 4. Välj rätt nätverkskort

Bridged-kortet måste kopplas till din dators fysiska nätverkskort. Ta reda på namnet:

```bash
VBoxManage list bridgedifs | grep -E "^Name:|^Wireless:|^Status:"
```

Exempel:

```
Name:            enp1s0
Wireless:        No
Status:          Up
Name:            wlp2s0
Wireless:        Yes
Status:          Up
```

Välj kortet som är **Up** och som du är ansluten via, och sätt det i `terraform.tfvars`:

```hcl
bridge_interface = "enp1s0"
```

> **Kabel vs. wifi:** Bridged fungerar tillförlitligt över **kabel**. Över **wifi**
> blockerar många accesspunkter trafik med "främmande" MAC-adresser, och nät med
> klientisolering stoppar det ofta helt. Funkar det inte på wifi – anslut kabel.

---

## 5. Kör

```bash
terraform init      # en gång – laddar ner VirtualBox-providern
terraform plan      # titta på vad som ska skapas
terraform apply     # skriv "yes" för att köra
```

Första gången tar det några minuter (boxen laddas ner). När det är klart:

```
Outputs:

servrar = {
  "ubuntu-terraform" = "192.168.1.42"
}
ssh_kommandon = [
  "ssh vagrant@192.168.1.42",
]
```

### Logga in

```bash
ssh vagrant@192.168.1.42      # lösenord: vagrant
```

Har du lagt till egna konton i `users` loggar du in med dem istället
(`ssh marcus@192.168.1.42`). Du kan också logga in direkt i **VirtualBox-fönstret**.
Första `ssh` mot en ny IP frågar om att lita på värdnyckeln – svara `yes`.

---

## 6. Inställningar – `terraform.tfvars`

All konfiguration görs i `terraform.tfvars` (läses automatiskt):

```hcl
vm_count = 3
hostname = "webb"

users = [
  { name = "marcus", password = "byt-mig", sudo = true },
  { name = "elev",   password = "elev123" },
]
```

### Antal maskiner

`vm_count` styr hur många VM:ar som skapas.

- `vm_count = 1` → en VM med namnet från `vm_name` (t.ex. `ubuntu-terraform`)
- `vm_count = 3` → `webb-01`, `webb-02`, `webb-03` (både VM-namn och hostname får suffix)

`terraform apply` skapar/tar bort maskiner tills antalet stämmer. Kör du många VM:ar
på en långsam dator: lägg till `-parallelism=2` för att ta dem några i taget.

### Hostname och användare

Vid `terraform apply` loggar Terraform in på **varje** server och:

- sätter hostname (`hostnamectl set-hostname`)
- skapar varje användare i `users` med lösenord, i `sudo`-gruppen om `sudo = true`

`users = []` (standard) → bara `vagrant` finns.

> Provisioneringen körs **när en VM skapas**. Ändrar du `users` i efterhand måste
> maskinerna byggas om: `terraform apply -replace=virtualbox_vm.ubuntu[0]` (en i taget)
> eller `terraform destroy && terraform apply` (alla).

### Övriga inställningar

| Variabel | Beskrivning | Standard |
|---|---|---|
| `vm_name` | Basnamn på VM:arna i VirtualBox | `"ubuntu-terraform"` |
| `cpus` | Antal vCPU per VM | `2` |
| `memory` | RAM per VM (`"2.0 gib"`, `"4.0 gib"`) | `"2.0 gib"` |
| `bridge_interface` | Värdens nätverkskort att brygga till | `"wlp2s0"` |
| `box_url` | Vilken Ubuntu-box | bento/ubuntu-24.04 |

---

## 7. Städa upp

```bash
terraform destroy
```

Den nedladdade boxen ligger kvar i `~/.terraform/virtualbox/gold/` (så nästa
`apply` går snabbare) – ta bort mappen manuellt om du vill frigöra diskutrymme.

---

## 8. Felsökning

| Symptom | Orsak / lösning |
|---|---|
| `VBoxManage: error: ... permission denied` | Du är inte med i gruppen `vboxusers`, eller har inte loggat ut/in efter att du lades till. Se steg 3b. |
| `Error: Nonexistent host networking interface, name 'wlp2s0'` | Fel namn i `bridge_interface`. Kör `VBoxManage list bridgedifs` och rätta värdet. |
| `apply` hänger på *"Waiting for VM ... ipv4_address"* och timeout efter 5 min | VM:en fick ingen IP. Nästan alltid **wifi som blockerar bridged** – anslut kabel. Kontrollera annars att du har DHCP på nätet. |
| `Error: unable to fetch remote image` | Ingen internetanslutning, eller så har box-URL:en blivit gammal. Hämta en ny version från [Vagrant-registret](https://portal.cloud.hashicorp.com/vagrant/discover/bento/ubuntu-24.04). |
| VM:en startar men visar *"No bootable medium found"* | Boxen i `box_url` kräver UEFI (t.ex. `bento/ubuntu-26.04`). Providern skapar bara BIOS-VM:ar. Använd en BIOS-box – `bento/ubuntu-24.04` (version 202510.26.0) är testad och fungerar. |
| `Error: can't create virtualbox VM ... exit status 1` | Rester från en tidigare körning. Kör `terraform destroy`, ta sedan bort `rm -rf ~/.terraform/virtualbox/machine/<vm-namn>` innan du försöker igen. |
| `Permission denied` när du SSH:ar | Fel lösenord – `vagrant` (eller det du satte i `users`). Gammal rad för samma IP i `~/.ssh/known_hosts`? Ta bort: `ssh-keygen -R <ip>`. |
| `Error: ... remote-exec ... timeout` | Terraform nådde inte servern via SSH för att sätta hostname/users. Oftast wifi-bryggan, eller att VM:en inte hann boota – kör `terraform apply` igen. |

Mer loggning:

```bash
export TF_LOG=INFO
terraform apply
```

---

