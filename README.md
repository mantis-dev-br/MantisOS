# MantisOS

Camada de serviços e automação para Orange Pi 5, com suporte a dispositivos IoT analógicos e digitais via placas ESP32.

> Funciona sem internet. Projetado para operar localmente com recuperação automática de falhas.

---

## O que é

MantisOS é um conjunto de serviços, scripts e configurações que transforma um Orange Pi 5 em uma central de controle local para equipamentos analógicos e digitais — câmeras IP, iluminação, alarme e reconhecimento facial — sem depender de nuvem para o funcionamento básico.

A comunicação com dispositivos não digitais é feita via placas ESP32 conectadas à rede local, controladas pela central.

---

## Arquitetura

```
Orange Pi 5 (MantisOS)
├── Wizard de configuração web (setup inicial)
├── Gerenciamento de rede (Ethernet + Wi-Fi)
├── Integração de câmeras IP via RTSP
├── Controle de iluminação
├── Integração com alarme existente (sem substituí-lo)
├── Reconhecimento facial local
└── CLI: mantisctl

ESP32 (dispositivos de borda)
└── Monitoria e controle de equipamentos analógicos
    via rede local
```

---

## Estrutura do repositório

```
bin/            Scripts executáveis e utilitários
config/         Arquivos de configuração dos serviços
deploy/         Scripts de instalação e provisionamento
docs/           Documentação do projeto
lib/            Bibliotecas e módulos compartilhados
scripts/        Scripts de manutenção e automação
services/
  network/      Configuração e recuperação de rede
```

---

## Fases de desenvolvimento

| Fase | Descrição | Status |
|------|-----------|--------|
| F0 | Inventário e requisitos | ✅ Concluído |
| F1 | Linux base e acesso administrativo | 🔄 Em andamento |
| F2 | Wizard Wi-Fi e recuperação de rede | ⏳ Pendente |
| F3 | Primeira câmera e gravação local | ⏳ Pendente |
| F4 | Iluminação e alarme | ⏳ Pendente |
| F5 | Reconhecimento facial | ⏳ Pendente |
| F6 | Imagem personalizada e atualização | ⏳ Pendente |

---

## Princípios

1. A central não substitui o funcionamento autônomo do alarme original.
2. Senhas e credenciais não entram no Git.
3. A rede de configuração é isolada da rede residencial.
4. Serviços essenciais iniciam automaticamente.
5. Falhas de internet não impedem automações locais.
6. Cada módulo pode ser testado separadamente.

---

## Hardware

| Componente | Especificação |
|------------|---------------|
| Central | Orange Pi 5 — 16 GB RAM |
| Dispositivos de borda | ESP32 (múltiplas unidades) |
| Câmeras | IP com suporte a RTSP |
| Conectividade | Ethernet + Wi-Fi |

---

## Requisitos

- Orange Pi 5 com Debian/Ubuntu ARM
- Python 3.10+
- Acesso à rede local

---

## Instalação

```bash
# Clone o repositório no Orange Pi
git clone https://github.com/mantis-dev-br/MantisOS.git
cd MantisOS

# Provisionamento inicial
sudo ./deploy/setup.sh
```

> ⚠️ Nenhuma credencial deve ser inserida nos arquivos de configuração commitados. Use variáveis de ambiente ou arquivos `.env` locais (já no `.gitignore`).

---

## CLI

```bash
mantisctl status        # Estado geral dos serviços
mantisctl restart <srv> # Reinicia um serviço específico
mantisctl logs <srv>    # Exibe logs do serviço
```

---

## Licença

Projeto pessoal — uso e distribuição sob consulta ao autor.

---

**Autor:** [Willian Rocha](https://github.com/mantis-dev-br) · [LinkedIn](https://www.linkedin.com/in/willian-rocha-dev/)
