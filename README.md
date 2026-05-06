# Formiga Rogue

Jogo roguelite 2D de plataforma desenvolvido em Godot 4.6.2.

## Como rodar

1. Instale o [Godot 4.6.2](https://godotengine.org/download)
2. Clone o repositório
3. Abra o Godot, clique em **Import** e selecione a pasta do projeto
4. Pressione **F5** para rodar

## Controles

| Ação | Tecla |
|------|-------|
| Mover | A / D ou ← / → |
| Pular / Duplo pulo | Space ou ↑ |
| Dash | Shift |
| Ataque leve (combo ×3) | Z |
| Ataque pesado | X |
| Parry | C |
| Interagir | F |
| Trocar arma | Q / Tab |

## Estado do desenvolvimento

| Task | Status |
|------|--------|
| T0 — Setup do projeto | ✅ |
| T1 — Movimento do personagem | ✅ |
| T2 — Sistema de combate base | ✅ |

## Estrutura do projeto

```
scenes/
  player/      → Player.tscn, PlayerHitbox.tscn
  enemies/     → DummyEnemy.tscn
  world/       → TestLevel.tscn (nível de teste)
scripts/
  player/      → Player.gd
  enemies/     → DummyEnemy.gd
assets/        → sprites, audio, fontes
resources/     → armas, itens
```

## Engine

- **Godot 4.6.2** — GL Compatibility
- Resolução base: 320×180 (pixel art)
- Janela: 960×540 (3× scale)
