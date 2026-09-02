<div align="center">

# ⚡ Ultimate Extreme Debloat & System Latency Optimizer

**Otimizador modular de baixa latência, expurgo de telemetria e remoção de bloatwares para Windows 10 e Windows 11.**

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Insider-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/blayk11)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://github.com/blayk11)
[![Author](https://img.shields.io/badge/Author-blayk11-black?style=for-the-badge&logo=github)](https://github.com/blayk11)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](https://github.com/blayk11)

</div>

---

## ⚡ Início Rápido (Execução Instantânea)

Abra o **PowerShell** (como Administrador) e cole o comando abaixo:

```powershell
irm https://raw.githubusercontent.com/blayk11/ultimatedebloat/main/ExtremeDebloat.ps1 | iex
```

> **Nota**: Não é necessário clonar o repositório nem baixar arquivos manualmente. O comando carrega a ferramenta diretamente na memória do terminal com suporte completo à interface interativa.

---

## 📌 Visão Geral

O **Ultimate Extreme Debloat & System Latency Optimizer** é um utilitário avançado em PowerShell projetado para transformar sistemas Windows em ambientes de altíssima performance, com mínima latência de entrada (input lag), zero micro-stutters e total privacidade.

Diferente de scripts convencionais que executam comandos às cegas, esta ferramenta possui uma **Interface Interativa de Terminal (TUI)** desenvolvida do zero, permitindo que você visualize, navegue e selecione exatamente o que deseja modificar ou remover do seu sistema operacional.

---

## ✨ Principais Destaques

* 🎮 **TUI Interativa Fluida (Zero Flicker)**: Interface de terminal com motor de paginação dinâmica e reposicionamento de cursor em memória, garantindo navegação suave sem travamentos ou oscilações de tela.
* 🛡️ **Segurança em Primeiro Lugar**: Criação integrada de Pontos de Restauração do Sistema (*System Restore Point*) antes de qualquer alteração profunda.
* 🧩 **100% Modular**: Você escolhe exatamente o que aplicar item por item via teclado, ou executa o **Modo Turbo Completo**.
* ⚡ **Kernel & Hardware Scheduling**: Ajustes refinados de quantum de CPU (`Win32PrioritySeparation`), prioridade de GPU e agendador multimídia para máximo FPS e estabilidade de frametime.
* 🔇 **Expurgo de Telemetria e Bloatware**: Desativação profunda de rastreamento em segundo plano, anúncios do Explorer, Windows Copilot e desinstalação permanente de apps UWP desnecessários.

---

## 🖥️ Demonstração da Interface (TUI)

```text
==========================================================================
         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              
             Criado por: blayk11 | https://github.com/blayk11             
==========================================================================
 [CATEGORIA]: REMOVER APLICATIVOS E BLOATWARES (UWP)
 Selecione com [ESPACO] os apps que deseja remover permanentemente.
 ------------------------------------------------------------------------
 [Setas / PgUp / PgDn]: Navegar  |  [Espaco]: Marcar/Desmarcar [X]
 [A]: Marcar Todos   |   [N]: Desmarcar Todos   |   [I]: Inverter
 [Enter]: Confirmar e Executar  |  [ESC / Q]: Cancelar / Voltar
 ========================================================================
   ^ (... mais itens acima ...)
 > [X] Clima (Bing Weather)
   [X] Noticias (Bing News)
   [X] Financas (Bing Finance)
   [X] Obter Ajuda (Get Help)
   [ ] Alarmes e Relogio
   [X] Clipchamp Video Editor
   [X] Microsoft Copilot App
   v (... mais itens abaixo ...)
 [ Item 1 de 37 | Marcados: 32/37 ] --------------------------------------
```

### 🎮 Atalhos e Controles de Navegação

| Tecla / Atalho | Ação |
| :--- | :--- |
| `▲ / ▼` (Setas) | Navega item por item com destaque em tempo real |
| `Page Up / Page Down` | Salta blocos de itens para navegação veloz |
| `Home / End` | Salta diretamente para o início ou final da lista |
| `Barra de Espaço` | Marca ou desmarca o item em foco (`[X]` / `[ ]`) |
| `A` | **Marca Todos** os itens da categoria |
| `N` | **Desmarca Todos** os itens |
| `I` | **Inverte a seleção** atual |
| `Enter` | **Confirma e executa** as alterações nos itens marcados |
| `ESC` ou `Q` | Cancela e retorna ao menu anterior sem alterar nada |

---

## 📦 Módulos do Sistema

### 1. 🛡️ Ponto de Restauração do Sistema
Cria um snapshot do estado atual do Windows via PowerShell antes de aplicar modificações no registro ou serviços.

### 2. 🗑️ Remoção de Bloatwares & Apps UWP
Desinstalação completa para o usuário atual e desprovisionamento da imagem do sistema de dezenas de apps promocionais (Bing Apps, Clipchamp, Copilot, Feedback Hub, Paciência, Jogos Patrocinados, Xbox Overlays desnecessários, etc.).

### 3. 🔒 Telemetria, Copilot AI & Anúncios
* Desativação de buscas web e Bing integrado no Menu Iniciar.
* Desativação do Microsoft Copilot AI e Windows Recall (Snapshot AI).
* Remoção de anúncios no Explorador de Arquivos e sugestões do Windows.
* Desativação de relatórios de telemetria, diagnóstico de dados e histórico de atividades.

### 4. ⚙️ Otimização de Serviços em Segundo Plano
Parada e desativação segura de serviços que causam alto consumo de CPU e constantes leituras de disco:
* `SysMain` (Superfetch - evita leituras redundantes e picos de uso em SSD/NVMe)
* `DiagTrack` & `dmwappushservice` (Telemetria e rastreamento de uso)
* `MapsBroker`, `Fax`, `RetailDemo`, `WpcMonSvc`, `WerSvc`, `PcaSvc`, etc.

### 5. 🚀 Ajustes Universais de Latência e Scheduling (CPU / RAM / GPU)
* **Win32PrioritySeparation = 38**: Configura ciclos curtos e variáveis com prioridade máxima de tempo de CPU para o aplicativo em foco/tela cheia.
* **Desativação de GameDVR**: Elimina captura de tela oculta e mitiga micro-stutters em jogos.
* **SystemResponsiveness = 0 & NetworkThrottling Off**: Desativa limites de prioridade de rede e multimídia.
* **GPU Priority = 8 & Scheduling Category High**: Garante prioridade no agendador de tarefas multimídia do Windows.
* **MenuShowDelay = 0**: Resposta imediata ao abrir pastas, menus e janelas.
* **Plano Ultimate Performance**: Desbloqueia e ativa o esquema de energia de Desempenho Máximo do Windows.

### 6. 🔓 Desativação de VBS / Isolamento de Núcleo
Desativa o hipervisor e segurança baseada em virtualização (VBS), eliminando o overhead de virtualização sobre a CPU e memória RAM para máximo rendimento em benchmarks e jogos competitivos.

### 7. 🧹 Limpeza Profunda de Disco e Caches
Purgamento seguro de arquivos temporários do sistema (`C:\Windows\Temp`), caches de usuário (`%TEMP%`), downloads pendentes do Windows Update, cache Prefetch e lixeira.

---

## 🚀 Métodos Alternativos de Execução

### Método Local (Download / Clone)
1. Clone o repositório:
   ```powershell
   git clone https://github.com/blayk11/ultimatedebloat.git
   ```
2. Acesse a pasta do projeto:
   ```powershell
   cd ultimatedebloat
   ```
3. Execute o script principal:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process -Force; .\ExtremeDebloat.ps1
   ```

*(Ou clique com o botão direito no `ExtremeDebloat.ps1` e selecione **"Executar com o PowerShell"**).*

---

## 👨‍💻 Autor

Desenvolvido e mantido por **[blayk11](https://github.com/blayk11)**.

Sinta-se à vontade para abrir uma *Issue* ou enviar um *Pull Request* com sugestões e melhorias!

---

## 📄 Licença

Este projeto está sob a licença [MIT](LICENSE). Sinta-se livre para utilizar, modificar e distribuir.
