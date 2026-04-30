# MP3 Craft — Design Tokens (из Figma)

Извлечено из Figma-документа через Talk To Figma MCP (channel `97hdzd61`).
Все размеры в логических пикселях (1:1 при референсе iPhone X = 375×812).

## Цвета

| Токен | Hex | Использование |
|---|---|---|
| `bg.primary` | `#111111` | основной фон Scaffold |
| `bg.surface` | `#14191F` | карточки истории, surface-блоки |
| `bg.image` | `#1C1C1C` | модал «Processing…» (квадрат 140×140) |
| `accent.gradientTop` | `#6298FF` | начало градиента (light) |
| `accent.gradientBottom` | `#1B63F8` | конец градиента (deep) |
| `accent.solid` | `#3F7EFB` | выбранный элемент / pause-кнопка / waveform |
| `accent.link` | `#4C39FE` | служебная (Cancel в keyboard, не использовать в UI) |
| `surface.dark` | `#14191F` | плеер-bar / time-pill |
| `text.primary` | `#FFFFFF` | основные тексты |
| `text.secondary` | `#FFFFFF` @ 70% | подзаголовки |
| `text.tertiary` | `#FFFFFF` @ 60% | подписи в модалах |
| `text.muted` | `#FFFFFF` @ 30% | placeholder |
| `text.faded` | `#FFFFFF` @ 25% | вторая часть длительности (16:23) |
| `danger.bg` | `#F42727` @ 15% | фон кнопки delete |
| `danger.icon` | `#F42727` | иконка delete |
| `youtube.red` | `#FF0000` | YouTube-логотип |

### Градиенты

**Primary gradient** (карточки/кнопки):
```
LinearGradient(
  begin: top, end: bottom,
  colors: [#6298FF (0%), #1B63F8 (100%)]
)
```

**Background ambient** (за всем экраном — большой эллипс 839×839, частично видимый сверху):
```
RadialGradient on Ellipse 839×839 absolute, smeared with same blue gradient
```

## Типографика

Шрифт: **Inter** (для основного текста), **SF Pro Text** (для status bar).
Подключается через пакет `google_fonts` (Inter) + системный SF Pro.

| Стиль | Параметры | Где используется |
|---|---|---|
| `display` | Inter ExtraBold 28 / lh 33.6 | "Craft" |
| `displaySora` | Sora Bold 28 / lh 33.6 | заголовок Erase Pix (в Figma как пример header — у нас не используется) |
| `appBarTitle` | Inter ExtraBold 24 / lh 28.8 | "Result", "Convert Files" |
| `subtitle` | Inter Medium 16 / lh 20.8 | "Convert audio or video into…" (white 70%) |
| `cardLabel` | Inter SemiBold 18 / lh 23.4 / ls -0.36 | "Gallery" / "Files" в IconCardButton |
| `sectionTitle` | Inter SemiBold 16 / lh 17.6 / ls -0.32 | "History" / "Choose Convertion Format" |
| `button` | Inter SemiBold 16 / lh 17.6 / ls -0.32 | "Save" / "Share" / "Convert" |
| `body` | Inter Medium 16 / lh 19.2 | "Paste your link" |
| `formatBadge` | Inter Medium 14 / lh 16.8 | "MP3" / "WAV" в Result |
| `formatBadgeSm` | Inter Medium 12 / lh 14.4 | "MP3" / "MP4" в History card |
| `duration` | Inter Medium 13 / lh 16.9 | "03:56", "13:03" в crop trimmer |
| `processing` | Inter Bold 24 / ls -0.48 / lh 28.8 | "Processing..." |
| `processingSub` | Inter Medium 16 / lh 19.2 | "Please stay on this screen…" (white 60%) |
| `statusBar` | SF Pro Text Semibold 17 / ls -0.408 / lh 22 | "9:41" |

## Размеры / отступы / радиусы

### Frame
- iPhone canvas: **375×812**
- StatusBar: 47px
- HomeIndicator: 134×5 radius 100, белый, отступ снизу 17px от низа экрана

### Header
- Высота: 56–62px (375×56 typical)
- Кнопки header: 38×38 radius 12, fill white@10%, stroke gradient white@5%→0%
- Иконка внутри кнопки: 24×24
- Title text centered

### Hero (Main Page top)
- Hero область: 375×229 (BG-frame с градиентом и иллюстрацией)
- "Craft" блок: width 116px, "Craft" 28px ExtraBold + (логотип hugeicons:mp3-01 42×42)
- Subtitle: 303×42, под иконкой/MP3-меткой
- Декоративная иллюстрация (3D mic + camera + sparkles + refresh-circle): занимает ≈ 175×178 в правой верхней части

### IconCardButton (Gallery / Files)
- 163.5×119, radius **24**
- Внутр. инсет: 16/16/14/16
- Декоративный круг (Ellipse 356×356, белый, в правом-верхнем углу — за пределами карты, размытый/обрезанный clip)
- Иконка-контейнер: **48×48** radius **12**, fill white, иконка внутри 36×36 (видна 24×24 внутри)
- Метка (label + chevron): bottom-left, "Gallery"/"Files" Inter SemiBold 18px white, chevron 20×20

### YouTube-карта (URL Input outer)
- 343×121, radius **24**, gradient
- Декоративный круг (Ellipse 356×356, белый, off-screen)
- Заголовок: link-icon 24×24 + YouTube-логотип 63×26 (PNG/SVG)
- Внутр. input: 307×48, radius **16**, fill white@15%
  - inset 14/14/14/14
  - link-icon 24×24 left
  - "Paste your link" Inter Medium 16, white@30%
  - clipboard-icon 24×24 right
- Когда введён URL: справа добавляется зелёный circle 36×36 с check (gradient #6298FF→#1B63F8 при focus / зелёный при success)

### History card
- Полная ширина row: 343, gap между card 13
- Card: **165×143**, radius **20**
- Format pill (top-left): height 22, radius 16, white@10% bg, label 12px
- More button (top-right): 28×28, radius 16, white@10%
- Duration pill (bottom-right): height 22, radius 16, white@10%, label 12px

### AppBar (Result/Crop Audio)
- Высота: 56 (status bar 47 + header 56)
- Close button (left): 38×38, radius 12, white@10% (у Crop — close-rounded; у Result — close-rounded)
- Title centered: "Result" / "Convert Files" Inter ExtraBold 24
- Action button (right): 38×38, radius 12; для Result — danger@15% delete; для Crop — нет (или check 36×36 для Process Loading)

### Project preview block (Result/Crop)
- 343×301 (с обложкой) или 343×175 (с иконкой ноты)
- Внутр. контейнер 311×301/175, radius **32**, white@5%
- Иконка музыкальной ноты 122×122, цвета `accent.solid`
- Format pills row (внутри блока, bottom-left): MP3 → arrow → WAV (filled) + 06:34 (right)

### Format pill (large, в preview)
- Height 25, radius 16
- Inactive: white@10% bg, white text Inter Medium 14
- Active (WAV): blue gradient, white text Inter Medium 14
- Стрелка между: lucide:arrow-right 20×20 white

### Crop Audio button (Result)
- Outline 343×48, radius 20, border `accent.solid` 1.5px
- Icon + Label, цвет `accent.solid`

### Player bar (Result)
- 343×76, radius 20, fill #14191F
- Pause button: 44×44, radius 33.5, fill `accent.solid`@20%, icon `accent.solid`
- Slider trackHeight 3, thumb 7px radius
- Position label слева, remaining label справа Inter Medium 13

### Crop trimmer (Crop Audio)
- Pill времени (выше): 155×29 radius 24, #14191F, Inter Medium 13
  - "03:56" white | "13:03" `accent.solid` | "16:23" white@25%
- Trimmer bar: 343×76 radius 20, #14191F + white@5%
- Pause inside: 44×44 radius 33.5, `accent.solid`@20%
- Range frames: левая шапка 24×73, средняя 179×73 stroke `accent.solid`, правая 24×73 — все три fill `accent.solid` mix

### Primary button (Save / Share / Convert)
- 343×56, radius **20**
- Gradient `#6298FF → #1B63F8`, stroke gradient white@20%→0%
- Label Inter SemiBold 16, white

### Format choice pill (Process Loading list)
- 165.5×53, radius **20**
- Inactive: white@5%, stroke gradient white@5%→0%
- Active: gradient `#6298FF → #1B63F8` 20% blue overlay
- Label Inter SemiBold 16 white centered

### Loading modal
- Overlay: full screen black@50%
- Card: 140×140, radius **42**, fill `#1C1C1C`
- Текст под карточкой:
  - "Processing..." Inter Bold 24 white
  - Subtitle Inter Medium 16 white@60%, lh 19.2

## Иконки (источник)

Дизайн использует:
- material-symbols (settings, close, delete-outline, history, check, pause)
- mingcute (link-line, ai-fill для sparkles)
- streamline-plump (gallery-2-solid, convert-pdf-1-solid)
- famicons (chevron-back)
- lucide (clipboard, arrow-right, crop-rounded)
- ant-design (audio-filled)
- hugeicons (mp3-01)
- solar (music-note-bold)
- tabler (video-filled)
- mdi (youtube)

В Flutter используем `Icons.*` из Material library + Cupertino. Где-то расхождение
форм (например, mingcute vs material) — допустимо, главное передать общий стиль.

3D-иллюстрации (микрофон, камера, refresh-circle, sparkles, MP3-document, music-note,
YouTube-логотип) — визуально специфичны. Реализуем 2 пути:

1. **Asset-based** (1:1 с Figma): пользователь экспортирует PNG из Figma (или
   повторно через MCP) и кладёт в `mobile/assets/images/`:
   - `hero_logo_3d.png` — композиция camera+mic+refresh+sparkles (≈540×285 @3x)
   - `mp3_doc_3d.png` — иконка-документ MP3
   - `mic_3d.png` — отдельный микрофон (для empty history)
   - `music_note_3d.png` — нота для preview
   - `youtube_logo.png` — YouTube logo (24px height)

2. **Fallback** (CustomPainter / Material icons + градиенты): если ассет не найден,
   используем code-based визуализацию — приблизительно близкую к Figma,
   но без 3D-теней и финальной полировки.

`AudioPreviewBlock`, `AppLogo`, `HistoryEmptyView` — все три имеют `assetPath`-параметр.
