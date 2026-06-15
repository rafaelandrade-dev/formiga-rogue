# Pixel Art — Besouro Patrulheiro no LibreSprite

## Por que o Besouro Patrulheiro?

Entre os inimigos da Zona 1, o Besouro Patrulheiro é o mais adequado para começar:

| Critério | Detalhe |
|---|---|
| Silhueta | Oval compacto — forma mais fácil de desenhar em poucos pixels |
| Animações necessárias | Walk, Idle, Windup, Charge, Hurt, Dead |
| Tamanho do hitbox | 14×10 px — cabe confortável em 24×20 |
| Cor base | Azul (#3373D9) — contraste fácil de trabalhar |
| Comportamento | Anda no chão, sem voo — walk cycle direto |

---

## 1. Configuração Inicial no LibreSprite

### 1.1 Criando o arquivo

1. Abra o LibreSprite
2. **File → New**
3. Preencha:
   - **Width:** `24`
   - **Height:** `20`
   - **Color Mode:** `RGB`
   - **Background:** `Transparent`
4. Clique em **OK**
5. **File → Save As** → salve em:
   ```
   assets/sprites/enemies/besouro_patrulheiro.aseprite
   ```

### 1.2 Zoom de trabalho

- Pressione `+` até o zoom chegar em **16x** (ou use a barra inferior)
- Ative a grade: **View → Show → Grid** e configure para **1×1 px**
- Ative o Pixel Preview: **View → Preview** — janela pequena ao lado mostrando o tamanho real

### 1.3 Configurar a paleta

Vá em **Palette → New Palette** e adicione exatamente estas cores (clique em cada slot e cole o hex):

| Slot | Cor | Hex | Uso |
|------|-----|-----|-----|
| 1 | Preto azulado | `#0D1117` | Contorno |
| 2 | Azul muito escuro | `#1A2E6B` | Sombra profunda |
| 3 | Azul escuro | `#2255AA` | Sombra do corpo |
| 4 | Azul médio | `#3373D9` | Corpo principal |
| 5 | Azul claro | `#5A9EFF` | Destaque suave |
| 6 | Azul bem claro | `#99CCFF` | Reflexo máximo |
| 7 | Vermelho | `#FF3333` | Olho |
| 8 | Cinza escuro | `#3A3A3A` | Pernas |
| 9 | Cinza médio | `#6A6A6A` | Pernas (highlight) |
| 10 | Branco acinzentado | `#CCCCCC` | Flash de dano |
| 11 | Laranja | `#E07820` | Flash de windup |
| 12 | Transparente | — | Fundo (já existe) |

> **Dica:** No LibreSprite, para editar uma cor da paleta, dê duplo clique no slot.

---

## 2. Anatomia do Besouro em Pixels

Antes de desenhar, entenda as partes. O besouro é visto de **perfil lateral** (lado direito):

```
Canvas 24×20  (cada caractere = 1 pixel)

     123456789012345678901234
  01 ........................
  02 ........................
  03 ....KK..................    ← antenas
  04 ...KMDK.................    ← ponta da antena
  05 ..KKKKKKKKKKK...........    ← topo da cabeça + corpo
  06 .KSSSSSMMMMMMMKK........    ← cabeça (sombra) + corpo
  07 KSRSSSMMLLMMMMMK........    ← olho (R) + corpo com highlight
  08 KSSSSSMMMMMMMMMK........    ← corpo
  09 KSSKKSMMMMMMMMMK........    ← divisão cabeça/corpo
  10 .KKKKMMMMMMMMMK.........    ← pescoço + corpo
  11 ....KMMMMMMMMK..........    ← corpo principal
  12 ....KMMMMMMMMK..........    ← corpo
  13 ....KKKKKKKKK...........    ← base do corpo
  14 ...K..K....K............    ← raiz das pernas
  15 ..K...K.....K...........    ← pernas superiores
  16 .K....K......K..........    ← pernas inferiores
  17 K.....K.......K.........    ← pés
  18 ........................
  19 ........................
  20 ........................

Legenda:
  K = Contorno (#0D1117)
  S = Sombra (#2255AA)
  M = Corpo médio (#3373D9)
  L = Highlight (#5A9EFF)
  R = Olho (#FF3333)
  . = Transparente
```

**Partes identificadas:**
- **Cabeça** (colunas 1–7, linhas 5–10): Oval menor, mais escura
- **Carapaça/Élitros** (colunas 4–17, linhas 5–13): Oval grande, corpo principal
- **Olho** (coluna 2, linha 7): 1–2 pixels vermelhos
- **Antenas** (colunas 3–6, linhas 3–4): Linha fina saindo da cabeça
- **Pernas** (linhas 14–17): 3 pernas visíveis do lado direito

---

## 3. Desenhando o Sprite Base (Frame 1 do Walk)

Use a ferramenta **Pencil (P)** com tamanho de ponta **1px** para tudo.

### Passo 1 — Contorno da carapaça

1. Selecione a cor `#0D1117` (Slot 1)
2. Desenhe um **oval horizontal** com estes pixels de borda:

```
Linha 5:  colunas 5 a 16   (linha reta de 12 px — topo)
Linha 6:  coluna 4 e 17    (expande 1 px para cada lado)
Linha 7:  coluna 4 e 17
Linha 8:  coluna 4 e 17
Linha 9:  coluna 4 e 17
Linha 10: coluna 4 e 17
Linha 11: coluna 4 e 17
Linha 12: coluna 4 e 17
Linha 13: colunas 5 a 16   (fecha o oval)
```

> **Dica:** Use a ferramenta **Ellipse (E)** do LibreSprite. Segure `Shift` para proporcional. Marque **"Hollow"** para só desenhar o contorno.
> Tamanho: ~13 px de largura × 9 px de altura, posicionado no centro-direita do canvas.

### Passo 2 — Preencher a carapaça

1. Selecione a cor `#3373D9` (Slot 4 — azul médio)
2. Use a ferramenta **Paint Bucket (G)** e clique dentro do oval
3. Agora selecione `#2255AA` (Slot 3 — azul escuro)
4. Pinte a **metade inferior** do oval pixel a pixel — colunas 4–17, linhas 10–13
   - Isso cria a sensação de volume: parte de cima iluminada, parte de baixo na sombra

### Passo 3 — Highlight da carapaça

1. Selecione `#5A9EFF` (Slot 5)
2. Pinte uma diagonal suave no **canto superior esquerdo** do oval:
   ```
   Linha 6:  colunas 6, 7, 8
   Linha 7:  colunas 5, 6, 7
   Linha 8:  colunas 5, 6
   ```
3. Selecione `#99CCFF` (Slot 6)
4. Adicione **1 único pixel** em (col 6, linha 6) — o ponto de luz máximo

### Passo 4 — Contorno da cabeça

1. Selecione `#0D1117` (Slot 1)
2. Desenhe um oval **menor** à esquerda, parcialmente sobrepondo a carapaça:
   ```
   Linha 5:  colunas 2, 3, 4   (topo da cabeça)
   Linha 6:  coluna 1 e 5      (laterais)
   Linha 7:  coluna 1 e 5
   Linha 8:  coluna 1 e 5
   Linha 9:  coluna 1 e 5
   Linha 10: colunas 2, 3, 4   (base da cabeça)
   ```

### Passo 5 — Preencher a cabeça

1. `#2255AA` (Slot 3): preencha o interior da cabeça
2. `#1A2E6B` (Slot 2): pinte as linhas 8–10 da cabeça (parte inferior mais escura)

### Passo 6 — Olho

1. Selecione `#FF3333` (Slot 7)
2. Pinte **1 pixel** em: coluna 2, linha 7
3. Opcional: adicione `#FF8888` (um vermelho mais claro) em coluna 2, linha 6 — dá brilho ao olho
   > Se não tiver esse rosa na paleta, adicione um slot extra com `#FF8888`

### Passo 7 — Antenas

1. Selecione `#0D1117` (Slot 1)
2. Pinte os pixels:
   ```
   Linha 4: coluna 3
   Linha 3: coluna 4
   Linha 2: coluna 5  ← ponta da antena (mais escura)
   ```
3. Selecione `#2255AA` e pinte coluna 3 na linha 5 — base da antena

### Passo 8 — Pernas (posição Walk Frame 1)

As pernas são **3 linhas diagonais** saindo da base do corpo:

```
Perna dianteira (frente):
  Linha 14: coluna 5   (raiz)
  Linha 15: coluna 4
  Linha 16: coluna 3
  Linha 17: coluna 2   (pé)

Perna mediana:
  Linha 14: coluna 9   (raiz)
  Linha 15: coluna 9
  Linha 16: coluna 10
  Linha 17: coluna 11  (pé)

Perna traseira:
  Linha 14: coluna 15  (raiz)
  Linha 15: coluna 16
  Linha 16: coluna 17
  Linha 17: coluna 18  (pé)
```

1. Selecione `#3A3A3A` (Slot 8) para as pernas
2. Desenhe cada perna seguindo os pixels acima
3. Selecione `#6A6A6A` (Slot 9) e adicione **1 pixel** de highlight na parte superior de cada perna (linha 14 de cada uma)

### Passo 9 — Linha divisória dos élitros

Os besouros têm uma linha no centro das asas. Adicione:

1. Selecione `#1A2E6B` (Slot 2)
2. Pinte uma linha diagonal suave:
   ```
   Linha 6:  coluna 10
   Linha 7:  coluna 11
   Linha 8:  coluna 11
   Linha 9:  coluna 12
   Linha 10: coluna 12
   Linha 11: coluna 13
   Linha 12: coluna 13
   ```
   Essa linha divide a carapaça ao meio, simulando as duas asas cobertas.

> Seu sprite base está pronto! Salve com `Ctrl+S`.

---

## 4. Ciclo de Caminhada — 4 Frames

O besouro anda para a direita. A caminhada tem **4 frames a 100ms cada** (10 FPS).

O que muda entre os frames:
- As **pernas** alternam posição (frente ↔ trás)
- O **corpo** sobe/desce **1 pixel** (bob)

### Como adicionar frames no LibreSprite

1. Na timeline (parte inferior): clique com botão direito no Frame 1 → **"Add Frame"** → repita até ter 4 frames
2. Para copiar o Frame 1 como base dos outros: clique no Frame 1, `Ctrl+C`, vá para o Frame 2, `Ctrl+V` → **Paste in Place**

### Frame 1 — Neutro (sprite base desenhado acima)

```
Corpo: posição normal
Perna dianteira: inclinada para frente (diagonal ↖)
Perna mediana:   reta para baixo
Perna traseira:  inclinada para trás (diagonal ↗)
```

### Frame 2 — Meio do passo (corpo desce 1px)

1. Vá para o Frame 2
2. Selecione **tudo** (`Ctrl+A`), mova o corpo **1 pixel para baixo** (`↓`)
3. Ajuste as pernas:

```
Perna dianteira: reta para baixo (contato com chão)
Perna mediana:   inclinada para trás (↗)
Perna traseira:  muito inclinada para trás
```

Pixelação das pernas — Frame 2:
```
Perna dianteira:
  L14: col 5, L15: col 5, L16: col 5, L17: col 5  (reta)

Perna mediana:
  L14: col 9, L15: col 10, L16: col 11, L17: col 12

Perna traseira:
  L14: col 15, L15: col 17, L16: col 18, L17: col 19
```

### Frame 3 — Oposto do Frame 1 (corpo volta ao normal)

1. Copie o Frame 1 como base
2. **Inverta as pernas** — o que estava na frente vai para trás e vice-versa:

```
Perna dianteira: agora inclinada para TRÁS (↗)
Perna mediana:   reta para baixo
Perna traseira:  agora inclinada para FRENTE (↖)
```

Pixelação das pernas — Frame 3:
```
Perna dianteira:
  L14: col 5, L15: col 4, L16: col 3, L17: col 2  (mesmo frame 1 mas vai para trás)
  → na verdade TROCA: L14: col5, L15: col6, L16: col7, L17: col8

Perna traseira:
  → agora vai para frente: L14: col15, L15: col14, L16: col13, L17: col12
```

### Frame 4 — Meio do passo oposto (corpo desce 1px)

- Corpo desce 1px novamente
- Inversão das pernas do Frame 2:

```
Perna dianteira: muito inclinada para trás
Perna mediana:   inclinada para frente (↖)
Perna traseira:  reta para baixo (contato)
```

> **Dica rápida:** Os frames 3 e 4 são essencialmente os frames 1 e 2 com as pernas espelhadas. Copie e ajuste só as pernas — não redesenhe tudo.

### Visualizando no LibreSprite

Pressione `Enter` ou clique no botão **Play** na timeline para ver a animação. A 100ms por frame (10 FPS), a caminhada deve parecer fluida e moderada.

---

## 5. Animação Idle — 2 Frames

O besouro parado tem uma animação sutil para não parecer "congelado".

**Frames: 2 | Duração: 500ms cada**

### Frame Idle 1
- Sprite base normal (mesma posição do Walk Frame 1)
- Antenas na posição padrão

### Frame Idle 2
- **Antenas sobem 1 pixel**: mova os 3 pixels das antenas 1 pixel para cima
- Opcional: adicione **1 pixel** de "barriga movendo" — pinte 1 pixel extra na linha 13 do corpo (simulando respiração)

```
Antenas Frame Idle 2:
  Linha 3: coluna 3  (era linha 4)
  Linha 2: coluna 4  (era linha 3)
  Linha 1: coluna 5  (era linha 2)
```

---

## 6. Animação de Ataque — 4 Frames

O Besouro tem **windup (0.8s)** seguido de **charge (0.45s)**. No script o corpo pisca laranja durante o windup.

**Total: 4 frames | Windup: 2 frames a 400ms | Charge: 2 frames a 100ms**

### Frames de Windup (corpo fica laranja piscando)

**Windup Frame 1 — Preparação**
1. Copie o sprite base (Walk Frame 1)
2. Selecione toda a área do corpo (`Ctrl+A` ou use Magic Wand na cor azul)
3. **Mude a cor do corpo** para `#E07820` (laranja, Slot 11)
   - Substitua os azuis médios pelo laranja
   - Azul médio → `#E07820`
   - Azul escuro → `#A05010`
   - Highlight azul → `#FF9930`
4. O besouro "se prepara": incline o corpo ligeiramente agachado
   - Mova tudo **1 pixel para baixo**
   - Pernas ficam mais "abertas" (encurtadas)

**Windup Frame 2 — Flash (corpo fica mais claro)**
1. Copie o Windup Frame 1
2. Substitua `#E07820` por `#FF9930` (laranja claro) — o "piscar"
3. Substitua `#A05010` por `#E07820`

> Na animação, os frames 1 e 2 do windup alternam rapidamente = efeito de "piscar laranja"

### Frames de Charge (corpo lançado para frente)

**Charge Frame 1 — Lançamento**
1. Copie o sprite base
2. **Incline** o corpo: mova os pixels da parte frontal (cabeça) **2 pixels para cima** e **2 pixels para a direita**
3. A cauda fica atrás — cria ângulo diagonal
4. Pernas recolhidas: reduza todas as pernas a 1–2 pixels (besouro está voando para frente)
5. Mude a cor para o azul original

```
Efeito visual do Charge Frame 1:
  Corpo inclinado ~30° para frente
  Antenas esticadas para trás (velocidade)
  Pernas recolhidas junto ao corpo
```

**Charge Frame 2 — Continuação**
- Quase igual ao Frame 1, mas mova tudo **2 pixels para a direita** em relação ao Frame 1
- Isso dá sensação de velocidade quando os frames alternam

---

## 7. Animação de Dano (Hurt) — 2 Frames

**2 frames | 100ms cada**

### Hurt Frame 1 — Flash branco
1. Copie o sprite base
2. Substitua **todas** as cores do corpo por `#CCCCCC` (branco acinzentado, Slot 10)
3. Mantenha só o contorno `#0D1117` e o olho vermelho

### Hurt Frame 2 — Volta às cores normais
- Sprite base normal

> A alternância rápida branco→normal dá o efeito de "tomou dano". No script isso fica ativo por 0.8s = ~8 ciclos desses 2 frames.

---

## 8. Animação de Morte (Dead) — 2 Frames

**2 frames | 150ms cada**

### Dead Frame 1 — Tombando
1. Copie o sprite base
2. Substitua todas as cores por tons de cinza:
   - Azul médio → `#555555`
   - Azul escuro → `#333333`
   - Highlight → `#777777`
3. **Gire** o sprite 45° (ou simule manualmente virando o oval)
4. As pernas ficam para cima (besouro de barriga para cima)

### Dead Frame 2 — Morto (estático)
1. Copie o Dead Frame 1
2. Desloque **2 pixels para baixo** — o corpo "afundou" no chão

---

## 9. Configurando Tags e Timeline no LibreSprite

Tags organizam as animações dentro do mesmo arquivo. No LibreSprite:

1. Clique com botão direito em qualquer frame na timeline
2. Selecione **"New Tag"**
3. Arraste para selecionar os frames corretos

| Tag | Frames | Duração/frame | Loop |
|-----|--------|---------------|------|
| `walk` | 1–4 | 100ms | Ping-pong ou Loop |
| `idle` | 5–6 | 500ms | Loop |
| `windup` | 7–8 | 400ms | Loop (até charge) |
| `charge` | 9–10 | 100ms | Loop |
| `hurt` | 11–12 | 100ms | Once |
| `dead` | 13–14 | 150ms | Once |

**Como criar cada tag:**
1. Na timeline, clique no ícone **"+"** de tag (ou `Ctrl+Shift+T`)
2. Dê o nome exato da tag (Godot vai usar esse nome)
3. Selecione os frames de início e fim
4. Escolha o tipo de loop

---

## 10. Exportando o Sprite Sheet

### Configuração de exportação

1. **File → Export Sprite Sheet**
2. Configure:
   - **Layout:** Horizontal Strip
   - **Sheet Type:** By Tag (exporta cada animação separada)
   - **Filename:** `besouro_patrulheiro_{tag}.png`
   - **Output folder:** `assets/sprites/enemies/`

**Ou export único (mais simples para começar):**
1. **File → Export Sprite Sheet**
2. **Layout:** Rows (por linhas)
3. Nome do arquivo: `besouro_patrulheiro.png`
4. Marque **"Save JSON data"** → gera o `besouro_patrulheiro.json` com os frames

### Estrutura dos arquivos gerados

```
assets/sprites/enemies/
  besouro_patrulheiro.aseprite    ← arquivo de trabalho
  besouro_patrulheiro.png         ← sprite sheet final
  besouro_patrulheiro.json        ← metadados dos frames (opcional)
```

---

## 11. Integrando no Godot 4

Depois de exportar o PNG, substitua o sprite procedural do Besouro no Godot:

### No script BesouroPatrulheiro.gd

Localize a função `_ready()` e **remova** o bloco de criação procedural de textura:

```gdscript
# REMOVA estas linhas (se existirem):
# var img := Image.create(14, 10, false, Image.FORMAT_RGB8)
# img.fill(Color(0.2, 0.45, 0.85))
# sprite.texture = ImageTexture.create_from_image(img)
```

### Na cena BesouroPatrulheiro.tscn

1. Abra a cena no editor Godot
2. Troque o nó `Sprite2D` por `AnimatedSprite2D`
3. Em **SpriteFrames**, clique em **"New SpriteFrames"**
4. Clique em **"Edit"** para abrir o editor
5. Para cada animação (walk, idle, etc.):
   - Clique no **"+"** para criar nova animação
   - Nomeie igual à tag do LibreSprite (ex: `walk`)
   - Arraste os frames do sprite sheet para a animação
   - Configure o FPS (walk = 10, idle = 2, hurt = 10)

### Ativando animações no script

Substitua as referências de `sprite` por `animated_sprite`:

```gdscript
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# No estado PATROL/CHASE:
animated_sprite.play("walk")

# No estado de windup:
animated_sprite.play("windup")

# No estado de charge:
animated_sprite.play("charge")

# No estado HURT:
animated_sprite.play("hurt")

# No estado DEAD:
animated_sprite.play("dead")
# Conecte o sinal animation_finished para liberar o nó após "dead"

# Para inverter direção (andando para esquerda):
animated_sprite.flip_h = true   # vira horizontalmente
```

---

## Resumo dos Frames

| Animação | Frames | ms/frame | Total |
|----------|--------|----------|-------|
| walk | 4 | 100ms | 400ms |
| idle | 2 | 500ms | 1000ms |
| windup | 2 | 400ms | 800ms |
| charge | 2 | 100ms | 200ms |
| hurt | 2 | 100ms | 200ms |
| dead | 2 | 150ms | 300ms |
| **Total** | **14 frames** | — | — |

---

## Dicas Finais para Pixel Art de Iniciante

1. **Anti-aliasing desligado sempre** — no LibreSprite, certifique que o Pencil está em modo "Pixel-perfect" (ícone de pixel na barra de ferramentas)
2. **Nunca use mais de 6–8 cores** por sprite neste tamanho — já a paleta acima está no limite
3. **Outline sempre em 1 cor só** — consistência no contorno deixa o sprite mais limpo
4. **Bob é essencial** — aquele 1 pixel de subida/descida no walk cycle transforma um sprite estático em algo vivo
5. **Olho chama atenção** — o pequeno pixel vermelho no olho é o que primeiro chama atenção do jogador; não pule essa parte
6. **Salve como .aseprite** — preserve o arquivo original; o PNG é só a exportação final
7. **Pixel perfect mode** — no LibreSprite, ative **View → Pixel-Perfect** para o lápis não criar pixels diagonais "sujos"
