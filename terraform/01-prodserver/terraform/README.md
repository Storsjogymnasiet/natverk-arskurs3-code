# Skapa din prod-server med Terraform

Din dev-server skapade du för hand i Proxmox. Prod-servern skapar du med
**Terraform**: en kodfil beskriver servern, och `terraform apply` bygger den.
Blir servern förstörd kör du samma kommando igen och får en identisk server.

När du är klar har du en Ubuntu-server i Proxmox som:

- heter `prod-<ditt-AD-namn>` (både VM-namn och hostname)
- har **statisk IP** (din Prod-IP från Excel i Teams), så du behöver inte röra Netplan
- har ditt användarkonto, som du loggar in på med SSH och lösenord
- startar automatiskt om Proxmox-värden startas om

---

## Dev och prod

| | Dev-servern | Prod-servern |
|---|---|---|
| Skapad | För hand i Proxmox | Med kod (`terraform apply`) |
| IP | Netplan för hand | cloud-init, direkt vid skapandet |
| SSH-inloggning | Lösenord | Lösenord → nyckel (uppgift senare) |
| Om den går sönder | Laga eller bygg om för hand | `terraform apply` igen |

**cloud-init** är ett program i Ubuntus cloud-avbild som körs vid första uppstarten.
Det läser inställningarna som Terraform skickar via Proxmox (IP, användare,
lösenord) och konfigurerar servern.

### Filerna i mappen

| Fil | Innehåll |
|---|---|
| `main.tf` | Själva servern: disk, CPU, RAM, nätverk, cloud-init |
| `variables.tf` | Vilka inställningar som finns och deras standardvärden |
| `outputs.tf` | Vad som skrivs ut efter `apply` (IP, ssh-kommando) |
| `setup.sh` | Frågar efter dina uppgifter och skriver `terraform.tfvars` |
| `terraform.tfvars.example` | Exempel på hur `terraform.tfvars` ser ut |
| `.gitignore` | Håller hemligheter och state utanför git |

---

## 1. Det här behöver du

- **Terraform**, som du installerade i lektion 03. Kontrollera med `terraform version`.
- **Din Prod-IP** från Excel-dokumentet i Teams (kolumnen Prod).
- **En API-token** från Proxmox. Skapa den så här:
  1. Logga in i Proxmox med ditt AD-konto.
  2. Gå till **Datacenter → Permissions → API Tokens → Add**.
  3. User: `<ditt-AD-namn>@valhalla`, Token ID: `terraform`.
  4. **Avmarkera "Privilege Separation"**.
  5. Kopiera **Secret** direkt. Den visas bara en gång.

---

## 2. Fyll i dina inställningar

Gå in i mappen och kör:

```bash
./setup.sh
```

(Får du `Permission denied`? Kör `chmod +x setup.sh` först.)

Skriptet frågar efter AD-användarnamn, API-token, nod, Prod-IP och lösenord,
och skriver filen `terraform.tfvars`. I slutet frågar det om du vill köra
`terraform init` och `terraform plan` direkt.

> ⚠️ `terraform.tfvars` innehåller din API-token och ditt lösenord. Den står i
> `.gitignore` och får **aldrig** checkas in eller delas.

---

## 3. Skapa servern

```bash
terraform init      # en gång: laddar ner Proxmox-providern
terraform plan      # läs igenom: vad kommer att skapas?
terraform apply     # skriv "yes"
```

Efter en till två minuter ser du något i stil med:

```
Outputs:

server = {
  "ip"    = "192.168.47.150"
  "namn"  = "prod-itjoab01"
  "vm_id" = 112
}
ssh_kommando = "ssh anna@192.168.47.150"
```

Vänta ungefär en minut till så att cloud-init hinner bli klart. Logga sedan in:

```bash
ssh anna@192.168.47.150
```

---

## 4. Ändra och bygga om

Vill du ändra något, t.ex. mer RAM, lägger du till en rad i `terraform.tfvars`:

```hcl
memory = 4096
```

Kör sedan `terraform plan` och **läs planen noga**:

- `~ update in-place`: servern ändras och finns kvar
- `-/+ must be replaced`: servern **rivs och skapas på nytt**, och allt du har
  gjort på den försvinner

> **Regel för prod:** kör aldrig `apply` utan att ha läst `plan`. En ersättning
> av en prod-server betyder driftstopp.

Ändra inte servern för hand i Proxmox. Ändra i koden, så stämmer koden och
servern alltid överens.

Riva servern helt: `terraform destroy`.

---

## 5. Felsökning

| Symptom | Orsak / lösning |
|---|---|
| `401 Unauthorized` / `authentication failure` | Fel API-token. Kör `./setup.sh` igen och klistra in rätt Secret. |
| `403 Forbidden ... Permission check failed` | Har du avmarkerat "Privilege Separation" på token? Annars: kontakta läraren. |
| `import ... does not exist` | Ubuntu-avbilden saknas på noden. Kontakta läraren. |
| `Prod-servrar får bara skapas på ...` | Noden måste vara `asgard-midgard003` eller `asgard-midgard004`. |
| `VM ... already exists` | VM-ID:t är upptaget. Ta bort raden `vm_id` i `terraform.tfvars`. |
| `Permission denied` vid SSH | Fel användarnamn eller lösenord, eller så är cloud-init inte klart. Vänta en minut. |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | Servern är ombyggd och har nya värdnycklar. Kör `ssh-keygen -R <ip>`. |
| Servern svarar inte på ping | Krockar IP-adressen med någon annans? Kontrollera Excel-listan. Logga in via Proxmox-konsolen och kör `ip a`. |
