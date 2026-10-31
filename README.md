# MantisOS

Camada de serviços e automação para Orange Pi 5, que integra equipamentos analógicos e digitais por meio de nós ESP32 em rede local.

> Projetado para funcionar sem internet, com recuperação automática de falhas.

---

## O que é

MantisOS é um conjunto de serviços, scripts e configurações que transforma um Orange Pi 5 em uma central de controle local para câmeras IP, iluminação, alarme e reconhecimento facial, sem depender de nuvem para o funcionamento básico.

Equipamentos sem interface digital nativa são lidos e acionados por placas ESP32 na rede local, coordenadas pela central.

O projeto é escrito em Shell (Bash) e C, sobre o kernel Linux e o NetworkManager da distribuição. A lógica da central é própria, sem plataformas de automação prontas.

---

## Estado atual

O que já funciona no hardware:

- `mantisctl`: CLI administrativa da central.
- Diagnóstico de sistema, memória, armazenamento e rede.
- Assistente Wi-Fi em terminal: estado, varredura e cadastro de perfis WPA/WPA2-PSK sem ativá-los e sem derrubar a conexão atual.
- Autorização mínima via Polkit para varredura Wi-Fi sem `sudo`.
- Link de gerência cabeado com IP fixo, independente do Wi-Fi.

Ainda não implementado: assistente web, ponto de acesso de configuração, câmeras, alarme, iluminação, nós ESP32 e reconhecimento facial.

---

## Arquitetura

```
Orange Pi 5 (MantisOS)
├── CLI: mantisctl                          ✅
├── Gerenciamento de rede (Ethernet + Wi-Fi) 🔄
├── Assistente de configuração web           ⏳
├── Integração de câmeras IP via RTSP        ⏳
├── Controle de iluminação                   ⏳
├── Integração com alarme existente          ⏳
│   (somente leitura, sem substituí-lo)
└── Reconhecimento facial local              ⏳

ESP32 (nós de borda)                         ⏳
└── Aquisição analógica e acionamento
    de equipamentos não digitais
```

---

## Estrutura do repositório

```
bin/            CLI mantisctl
config/         Exemplo de configuração da central
deploy/         Instaladores e regras de sistema
  network/      Link de gerência cabeado
  polkit/       Regras de autorização
docs/           Documentação do projeto
lib/            Funções compartilhadas em Shell
scripts/        Diagnóstico e manutenção
services/
  network/      Assistente Wi-Fi
```

---

## Fases de desenvolvimento

| Fase | Descrição | Status |
|------|-----------|--------|
| F0 | Inventário e requisitos | 🔄 Central inventariada; periféricos pendentes |
| F1 | Linux base e acesso administrativo | 🔄 Em andamento |
| F2 | Assistente Wi-Fi e recuperação de rede | 🔄 Assistente em terminal funcional |
| F3 | Primeira câmera e gravação local | ⏳ Pendente |
| F4 | Iluminação e alarme | ⏳ Pendente |
| F5 | Reconhecimento facial | ⏳ Pendente |
| F6 | Imagem personalizada e atualização | ⏳ Pendente |

---

## Princípios

1. A central não substitui o funcionamento autônomo do alarme original.
2. Senhas e credenciais não entram no Git nem nos argumentos de processos.
3. A rede de configuração é isolada da rede residencial.
4. Serviços essenciais iniciam automaticamente.
5. Falhas de internet não impedem automações locais.
6. Cada módulo pode ser testado separadamente.

---

## Hardware

| Componente | Especificação |
|------------|---------------|
| Central | Orange Pi 5 (RK3588S), 16 GB RAM, NVMe 256 GB |
| Wi-Fi | Adaptador USB (o Orange Pi 5 não tem Wi-Fi onboard) |
| Nós de borda | ESP32 |
| Câmeras | IP com RTSP |

---

## Requisitos

- Orange Pi 5 com Debian 12 (testado na imagem Orange Pi 1.1.8, kernel 6.1.43-rockchip-rk3588)
- Bash, NetworkManager e Polkit
- Usuário `orangepi` com acesso a `sudo` (a regra Polkit atual é escrita para esse usuário)

---

## Instalação

```bash
git clone https://github.com/mantis-dev-br/MantisOS.git ~/Projetos/MantisOS
cd ~/Projetos/MantisOS

# Disponibiliza o mantisctl no PATH do usuário
mkdir -p ~/.local/bin
ln -sf "$PWD/bin/mantisctl" ~/.local/bin/mantisctl

# Permite varredura Wi-Fi sem sudo (apenas essa ação)
sudo ./deploy/install-polkit-rules.sh

# Link de gerência cabeado (IP fixo, sem rota padrão)
sudo ./deploy/network/install-management-link.sh
```

Se `~/.local/bin` não estiver no `PATH`, acrescente `export PATH="$HOME/.local/bin:$PATH"` ao `~/.bashrc`.

### Link de gerência

A porta Ethernet da central é reservada ao acesso administrativo e de recuperação: IP fixo `10.77.0.1/24`, sem gateway e sem DNS, nunca usada como rota padrão. Assim o acesso continua disponível quando o Wi-Fi está fora do ar, em modo de configuração ou mal configurado.

Ligue um computador direto na porta Ethernet e configure nele `10.77.0.2/24`, também sem gateway. Interface e endereço podem ser alterados com `MANTIS_MGMT_IFACE` e `MANTIS_MGMT_ADDRESS`.

---

## CLI

```bash
mantisctl status          # Modelo, kernel, memória e armazenamento
mantisctl network         # Interfaces, endereços, rotas e NetworkManager
mantisctl services        # Serviços em execução
mantisctl wifi status     # Estado das interfaces e rota padrão
mantisctl wifi scan       # Varredura de redes Wi-Fi
mantisctl wifi configure  # Cadastra um perfil WPA/WPA2-PSK sem ativá-lo
```

O `wifi configure` grava o perfil diretamente no diretório de conexões do NetworkManager, com permissão `0600`, e pede a senha sem exibi-la. A senha nunca é passada como argumento de comando.

Para diagnóstico completo da placa:

```bash
./scripts/diagnose.sh
```

---

## Licença

Todos os direitos reservados. O código está publicado para consulta; uso, cópia e distribuição dependem de autorização do autor.

---

**Autor:** [Willian Rocha](https://github.com/mantis-dev-br) · [LinkedIn](https://www.linkedin.com/in/willian-rocha-dev/)
