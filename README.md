# Clipboard Alpha — Preserve Transparency in Windows Clipboard

A Delphi/VCL unit that preserves alpha channel when copying/pasting 32-bit images with transparency through the Windows clipboard.

## Problem

Standard VCL `TClipboard.Assign` loses alpha channel — copied images become fully opaque.

## Solution

`IP76.Imaging.Clipbrd` implements cascading approach:

**Load (TryLoadGraphicFromClipboard):**
1. PNG — best quality with alpha preserved
2. CF_DIBV5 — manual parsing of 32-bit bitmap data
3. Standard VCL — fallback

**Save (TrySaveGraphicToClipboard):**
- Writes PNG + CF_DIBV5 simultaneously
- Windows automatically generates CF_DIB/CF_BITMAP from CF_DIBV5

## Usage

```pascal
// Paste with alpha
var G: TGraphic;
begin
  if TryLoadGraphicFromClipboard(G) then
    try
      Image1.Picture.Assign(G);
    finally
      G.Free;
    end;
end;

// Copy with alpha
TrySaveGraphicToClipboard(Image1.Picture.Graphic);
```

## Demo Application

The demo allows side-by-side comparison:
- **VCL** — standard behavior (alpha lost)
- **IP76** — enhanced behavior (alpha preserved)

**Hotkeys:**
- *Ctrl+C / Ctrl+V* — standard VCL
- *Ctrl+Shift+C / Ctrl+Shift+V* — IP76 module

## Requirements

- Delphi 10+ (VCL)
- Windows (tested on Windows 10/11)

## Article (Russian)

Detailed explanation with screenshots:
**[https://ip76.ru/clipbrd-alpha/](https://ip76.ru/clipbrd-alpha/)**

## License

[MIT](LICENSE)

