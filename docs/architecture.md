# Arquitetura inicial

## Hardware
- Orange Pi 5
- 16 GB RAM
- Armazenamento a definir
- Wi-Fi a validar
- 3 a 5 câmeras IP
- Central de alarme ainda não identificada
- Iluminação a integrar

## Camadas

1. Linux ARM64
2. Rede e provisionamento
3. Serviços gerenciados pelo systemd
4. Motor de automação
5. API própria
6. Interface web
7. Integrações de hardware

## Rede

- Ethernet: acesso administrativo e recuperação.
- Wi-Fi cliente: rede residencial.
- Ponto de acesso: somente configuração inicial.
- Acesso remoto: VPN, em fase posterior.

## Segurança

- O alarme original continua autônomo.
- A integração inicial será somente de leitura.
- Nenhum GPIO será conectado a circuito desconhecido.
- Credenciais não serão registradas nos logs.
- A configuração de rede deve prever recuperação.

## Armazenamento

Sistema e dados devem ser separados logicamente.
Vídeos devem ter política de retenção configurável.
O sistema deve tolerar reinicializações inesperadas.
