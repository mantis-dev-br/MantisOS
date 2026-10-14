# CasaOS — Central Residencial

Central de automação residencial local para Orange Pi 5
com 16 GB de RAM.

## Objetivos

- Funcionamento básico sem internet.
- Configuração inicial por wizard web.
- Conexão por Ethernet e Wi-Fi.
- Integração de câmeras IP via RTSP.
- Integração segura com alarme existente.
- Controle de iluminação.
- Reconhecimento facial local.
- Atualização e recuperação reproduzíveis.

## Princípios

1. A central não substitui o funcionamento autônomo
   do alarme original.
2. Senhas e credenciais não entram no Git.
3. A rede de configuração é isolada da rede residencial.
4. Serviços essenciais devem iniciar automaticamente.
5. Falhas de internet não podem impedir automações locais.
6. Cada módulo deve poder ser testado separadamente.

## Fases

- [ ] F0: inventário e requisitos
- [ ] F1: Linux base e acesso administrativo
- [ ] F2: wizard Wi-Fi e recuperação de rede
- [ ] F3: primeira câmera e gravação local
- [ ] F4: iluminação e alarme
- [ ] F5: reconhecimento facial
- [ ] F6: imagem personalizada e atualização
