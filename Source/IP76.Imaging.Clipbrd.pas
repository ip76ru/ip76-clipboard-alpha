//******************************************************************************
//  Project: IP76.RU
//  Created: 2026-02-12
//  Article: https://ip76.ru/clipbrd-alpha/
//  Description: Module for clipboard image exchange
//    without losing the alpha channel
//  Описание: Модуль для обмена изображениями через буфер обмена
//    без потери альфа-канала
//------------------------------------------------------------------------------
//  function TryLoadGraphicFromClipboard(out Graphic: TGraphic): Boolean;
//  Loading from clipboard:
//    Standard VCL (TPicture/TClipboard) loses alpha channel on paste
//    The function implements cascading load: first tries PNG,
//    then CF_DIBV5 with manual alpha parsing, and only then,
//    if nothing worked, falls back to standard VCL mechanism
//  Загрузка из буфера:
//    Стандартный VCL (TPicture/TClipboard) теряет альфа-канал при вставке
//    Функция реализует каскадную загрузку: сначала пробуем PNG,
//    затем CF_DIBV5 с ручным разбором альфы, и только потом,
//    если ничего не сработало, используем стандартный механизм VCL
//------------------------------------------------------------------------------
//  function TrySaveGraphicToClipboard(Graphic: TGraphic): Boolean;
//  Saving to clipboard:
//    The function puts both PNG and CF_DIBV5 with alpha channel
//    CF_DIB и CF_BITMAP Windows синтезирует автоматически
//    CF_DIB and CF_BITMAP are synthesized by Windows automatically
//  Сохранение в буфер:
//    Стандартный VCL кладёт только CF_BITMAP, получатель может не увидеть альфу
//    Функция кладёт сразу PNG и CF_DIBV5 с альфа-каналом
//    CF_DIB и CF_BITMAP Windows синтезирует автоматически
//******************************************************************************

// Enables heuristic detection of premultiplied alpha when reading CF_DIBV5.
// The CF_DIBV5 format does not contain information about the alpha type.
//
// Without this directive, data is treated as straight alpha (not premultiplied) -
// VCL will perform premultiply on its own when AlphaFormat is set.
// This is the safe option for most applications (Paint.NET, GIMP, etc.).
//
// With this directive, the IsPremultiplied function checks pixels:
// if all RGB <= A - data is considered premultiplied, AlphaFormat
// is set BEFORE copying to avoid double multiplication.
//
// Side effect: the heuristic does not guarantee 100% accuracy -
// dark straight-alpha pixels also satisfy the RGB <= A condition.
// -----------------------------------------------------------------------------
// Включает эвристическое определение premultiplied alpha при чтении CF_DIBV5.
// Формат CF_DIBV5 не содержит информации о типе альфа-канала.
//
// Без этой директивы данные считаются straight alpha (не premultiplied) -
// VCL выполнит premultiply самостоятельно при установке AlphaFormat.
// Это безопасный вариант для большинства приложений (Paint.NET, GIMP и др.).
//
// С этой директивой функция IsPremultiplied проверяет пиксели:
// если все RGB <= A - данные считаются premultiplied, AlphaFormat
// устанавливается ДО копирования, чтобы избежать повторного умножения.
//
// Побочный эффект: эвристика не даёт 100% гарантии -
// тёмные straight-пиксели тоже удовлетворяют условию RGB <= A.

{$DEFINE CHECK_Premultiplied}

unit IP76.Imaging.Clipbrd;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Imaging.PngImage;

// Cascading image load from clipboard
// Tries formats in priority order: PNG -> CF_DIBV5 -> standard VCL
// Returns True if loading succeeded
// Graphic is created inside - caller is responsible for freeing it
//
// Каскадная загрузка изображения из буфера обмена
// Пробует форматы в порядке приоритета: PNG -> CF_DIBV5 -> стандартный VCL
// Возвращает True, если удалось загрузить
// Graphic создаётся внутри - вызывающий отвечает за освобождение
function TryLoadGraphicFromClipboard(out Graphic: TGraphic): Boolean;

// Load PNG from clipboard
// Many applications (browsers, graphic editors) place PNG -
// this is the best option, alpha channel is preserved as-is
// Result is converted to TBitmap to avoid
// scaling issues in TPngImage.Draw
//
// Загрузка PNG из буфера обмена
// Многие приложения (браузеры, графические редакторы) кладут PNG -
// это лучший вариант, альфа-канал сохраняется как есть
// Результат конвертируется в TBitmap, чтобы избежать проблем
// с масштабированием в TPngImage.Draw
function TryLoadPNG(out Graphic: TGraphic): Boolean;

// Load CF_DIBV5 with manual alpha channel parsing
// CF_DIBV5 format supports 32-bit pixels with alpha,
// but VCL does not handle it - we parse manually
// If alpha channel is empty (all zeros), fill with 255 (fully opaque)
//
// Загрузка CF_DIBV5 с ручным разбором альфа-канала
// Формат CF_DIBV5 поддерживает 32-битные пиксели с альфой,
// но VCL его не обрабатывает, разбираем вручную
// Если альфа-канал пуст (все нули), то заполняем 255 (полная непрозрачность)
function TryLoadDIBV5(out Graphic: TGraphic): Boolean;

// Load via standard VCL mechanism (TClipboard.Assign)
// Загрузка через стандартный механизм VCL (TClipboard.Assign)
function TryLoadVCL(out Graphic: TGraphic): Boolean;

// Cascading image copy to clipboard
// Places PNG + CF_DIBV5 for applications that support alpha,
// CF_DIB/CF_BITMAP are synthesized by Windows automatically
// Returns True if at least one format was placed successfully
//
// Каскадное копирование изображения в буфер обмена
// Кладёт PNG + CF_DIBV5 для приложений с поддержкой альфы,
// CF_DIB/CF_BITMAP Windows синтезирует автоматически
// Возвращает True, если удалось положить хотя бы один формат
function TrySaveGraphicToClipboard(Graphic: TGraphic): Boolean;

// Places image into clipboard as PNG
// For applications that understand PNG (browsers, Photoshop, GIMP)
//
// Кладёт изображение в буфер как PNG
// Для приложений, понимающих PNG (браузеры, Photoshop, GIMP)
function TrySavePNG(Graphic: TGraphic): Boolean;

// Places image into clipboard as CF_DIBV5 with alpha channel
// For applications that read DIB with alpha but do not read PNG
//
// Кладёт изображение в буфер как CF_DIBV5 с альфа-каналом
// Для приложений, читающих DIB с альфой, но не читающих PNG
function TrySaveDIBV5(Graphic: TGraphic): Boolean;

// Places image into clipboard via standard VCL mechanism (TClipboard.Assign).
// Кладёт изображение в буфер через стандартный механизм VCL (TClipboard.Assign).
function TrySaveVCL(Graphic: TGraphic): Boolean;

// Convert TBitmap to TPNGImage preserving the alpha channel
// Конвертировать TBitmap в TPNGImage с переносом альфа-канала
function BitmapToPNG(ABitmap: TBitmap): TPNGImage;

// Adds Unicode text to clipboard without clearing other formats
// (for example, PNG / CF_DIBV5)
// Добавляет Unicode-текст в буфер, не очищая остальные форматы
// (например PNG / CF_DIBV5)
function TrySaveStringToClipboard(const Value: string): Boolean;

// Reads Unicode text from clipboard
// Returns False if CF_UNICODETEXT is absent or malformed
// Читает Unicode-текст из буфера
// Возвращает False, если CF_UNICODETEXT отсутствует или повреждён
function TryLoadStringFromClipboard(out Value: string): Boolean;

implementation

uses
  Vcl.Clipbrd;

var
  CF_PNG: Word;

{$Region 'Helper functions (loading from clipboard)'}
// Вспомогательные функции (загрузка из буфера)

// Reads raw format data from clipboard into a stream
// Returns nil if format is not available or data is empty
//
// Читает сырые данные формата из буфера обмена в поток
// Возвращает nil, если формат отсутствует или данные пусты
function GetClipboardStream(AFormat: Word): TMemoryStream;
var H: THandle; Ptr: Pointer; Size: NativeUInt;
begin
  Result := nil;

  Clipboard.Open;
  try
    H := Clipboard.GetAsHandle(AFormat);
    if H = 0 then
      exit;

    Ptr := GlobalLock(H);
    if Ptr = nil then
      exit;

    try
      Size := GlobalSize(H);
      if Size = 0 then
        exit;

      Result := TMemoryStream.Create;
      Result.WriteBuffer(Ptr^, Size);
      Result.Position := 0;
    finally
      GlobalUnlock(H);
    end;
  finally
    Clipboard.Close;
  end;
end;

// Checks if there is at least one non-zero alpha value in the pixel array
// If all alpha bytes are zero, the alpha channel is not filled (synthesized by Windows)
//
// Проверяет, есть ли в массиве пикселей хотя бы одно ненулевое значение альфы
// Если все альфа-байты нулевые, значит альфа-канал не заполнен (синтезирован Windows)
function HasAlpha(Bits: PByte; PixelCount: Integer): Boolean;
var I: Integer; P: PByte;
begin
  Result := False;
  P := Bits;
  // move to the first alpha byte (BGRA layout => offset 3)
  // встаём на первый альфа-байт (тут BGRA => смещение 3)
  Inc(P, 3);

  for I := 0 to PixelCount - 1 do
  begin
    if P^ <> 0 then
      exit(True);
    Inc(P, 4);
  end;
end;

// Force-fills the alpha channel with 255 (fully opaque).
// Принудительно заполняет альфа-канал значением 255 (полная непрозрачность).
procedure FillAlpha(Bits: PByte; PixelCount: Integer);
var I: Integer; P: PByte;
begin
  P := Bits;
  Inc(P, 3);

  for I := 0 to PixelCount - 1 do
  begin
    P^ := 255;
    Inc(P, 4);
  end;
end;

// Heuristic check: whether pixel data is premultiplied
// Эвристическая проверка: являются ли пиксельные данные premultiplied
function IsPremultiplied(Bits: PByte; PixelCount: Integer): Boolean;
{$IFDEF CHECK_Premultiplied}
var I: Integer; P: PByteArray;
{$ENDIF}
begin
{$IFNDEF CHECK_Premultiplied}
  exit(False);
{$ELSE}
  // If any color component > alpha,
  // data is definitely NOT premultiplied
  // Если хотя бы один цветовой компонент > альфы,
  // данные точно НЕ premultiplied
  P := PByteArray(Bits);
  for I := 0 to PixelCount - 1 do
  begin
    // BGRA: [0]=B, [1]=G, [2]=R, [3]=A
    if (P[0] > P[3]) or
       (P[1] > P[3]) or
       (P[2] > P[3]) then
      exit(False);
    P := PByteArray(@P[4]);
  end;
  // All components <= alpha - compatible with premultiplied
  // (but does not prove it 100%)
  // Все компоненты <= альфы - совместимо с premultiplied
  // (но не доказывает это на 100%)
  Result := True;
{$ENDIF}
end;

{$EndRegion}

{$Region 'Loading from clipboard'}
// Загрузка из буфера обмена

// Load PNG
// Загрузка PNG
function TryLoadPNG(out Graphic: TGraphic): Boolean;
var S: TMemoryStream; Png: TPngImage; Bmp: TBitmap;
begin
  Result := False;
  Graphic := nil;

  if CF_PNG = 0 then
    exit;

  S := GetClipboardStream(CF_PNG);
  if S = nil then
    exit;

  Png := TPngImage.Create;
  try
    try
      Png.LoadFromStream(S);
    finally
      S.Free;
    end;

    // Convert to TBitmap.
    // TPngImage.Draw has minor scaling bugs:
    //   https://ip76.ru/tpngimage-stretch-bug/
    // TBitmap.Draw delegates scaling to WinAPI, no issues.
    // Конвертируем в TBitmap.
    // TPngImage.Draw при масштабировании слегка глючит:
    //   https://ip76.ru/tpngimage-stretch-bug/
    // TBitmap.Draw делегирует масштабирование WinAPI, и нет проблем.
    Bmp := TBitmap.Create;
    try
      Bmp.Assign(Png);
      Graphic := Bmp;
      Result := True;
    except
      Bmp.Free;
      raise;
    end;
  finally
    Png.Free;
  end;
end;

// Load CF_DIBV5
// Загрузка CF_DIBV5
function TryLoadDIBV5(out Graphic: TGraphic): Boolean;
var
  Stream: TMemoryStream;
  Header: PBitmapV5Header;
  Bits: PByte;
  Width, Height: Integer;
  TopDown: Boolean;
  Bmp: TBitmap;
  Y, SrcY: Integer;
  SrcRow, DstRow: PByte;
  RowSize: Integer;
  HasRealAlpha: Boolean;
  AlreadyPremultiplied: Boolean;
begin
  Result := False;
  Graphic := nil;

  Stream := GetClipboardStream(CF_DIBV5);
  if Stream = nil then
    exit;

  try
    // Check minimum size
    // Проверяем минимальный размер
    if Stream.Size < SizeOf(TBITMAPV5HEADER) then
      exit;

    Header := PBitmapV5Header(Stream.Memory);

    // Only handle 32-bit data - only it contains an alpha channel.
    // Everything else is better left to the standard CF_DIB handler.
    // Работаем только с 32-битными данными, только они содержат альфа-канал.
    // Остальное проще отдать стандартному обработчику CF_DIB.
    if Header^.bV5BitCount <> 32 then
      exit;

    Width := Header^.bV5Width;
    Height := Abs(Header^.bV5Height);
    TopDown := Header^.bV5Height < 0;

    if (Width <= 0) or (Height <= 0) then
      exit;

    // Pixel data follows immediately after the header
    // Пиксельные данные идут сразу за заголовком
    Bits := PByte(Stream.Memory) + SizeOf(TBITMAPV5HEADER);
    RowSize := Width * 4;

    // Verify that there is enough data
    // Проверяем, что данных достаточно
    if Stream.Size < SizeOf(TBITMAPV5HEADER) +
      NativeUInt(RowSize) * NativeUInt(Height) then
      exit;

    // If alpha channel is empty, fill with 255.
    // This happens when CF_DIBV5 is synthesized by Windows from CF_DIB
    // that had no alpha.
    //
    // Если альфа-канал пуст, то заполняем 255.
    // Такое бывает, когда CF_DIBV5 синтезирован Windows из CF_DIB,
    // в котором альфы не было.
    HasRealAlpha := HasAlpha(Bits, Width * Height);
    if not HasRealAlpha then
      FillAlpha(Bits, Width * Height);
    AlreadyPremultiplied := HasRealAlpha and
      IsPremultiplied(Bits, Width * Height);

    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf32bit;
      // Data is already premultiplied - set BEFORE copying,
      // otherwise VCL will multiply RGB by A again when
      // AlphaFormat is set later (causes gray fringe on edges)
      //
      // Данные уже premultiplied - ставим ДО копирования,
      // иначе VCL при последующей установке AlphaFormat
      // умножит RGB на A повторно (серая кайма на краях)
      if AlreadyPremultiplied then
        Bmp.AlphaFormat := afPremultiplied;
      Bmp.SetSize(Width, Height);

      // Copy rows considering the order.
      // DIB stores rows bottom-up by default (bottom-up, bV5Height > 0).
      // TBitmap.ScanLine[0] is always the top row.
      //
      // Копируем строки с учётом порядка.
      // DIB по умолчанию хранит строки снизу вверх (bottom-up, bV5Height > 0).
      // TBitmap.ScanLine[0] - всегда верхняя строка.
      for Y := 0 to Height - 1 do
      begin
        if TopDown then
          SrcY := Y
        else
          SrcY := Height - 1 - Y;

        SrcRow := Bits + NativeUInt(SrcY) * NativeUInt(RowSize);
        DstRow := Bmp.ScanLine[Y];
        Move(SrcRow^, DstRow^, RowSize);
      end;

      // Data is straight alpha - set AFTER copying,
      // so that VCL performs the required RGB * A multiplication
      // Данные straight alpha - ставим ПОСЛЕ копирования,
      // чтобы VCL выполнил нужное умножение RGB на A
      if HasRealAlpha then
        if not AlreadyPremultiplied then
          Bmp.AlphaFormat := afPremultiplied;

      Graphic := Bmp;
      Result := True;
    except
      Bmp.Free;
      raise;
    end;
  finally
    Stream.Free;
  end;
end;

// Load via standard VCL
// Загрузка через стандартный VCL
function TryLoadVCL(out Graphic: TGraphic): Boolean;
var Pic: TPicture;
begin
  Result := False;
  Graphic := nil;

// Redundant guard - error protection is already provided
// by subsequent try/except and nil/Empty checks.
// Лишняя перестраховка, защита от ошибок уже обеспечена
// последующими try/except и проверками nil/Empty.
//  if not Clipboard.HasFormat(CF_BITMAP) then
//    exit;

  Pic := TPicture.Create;
  try
    try
      Pic.Assign(Clipboard);
    except
      exit;
    end;

    if (Pic.Graphic = nil) or Pic.Graphic.Empty then
      exit;

    Graphic := TBitmap.Create;
    try
      Graphic.Assign(Pic.Graphic);
      Result := True;
    except
      FreeAndNil(Graphic);
    end;
  finally
    Pic.Free;
  end;
end;

// Cascading load
// Каскадная загрузка
function TryLoadGraphicFromClipboard(out Graphic: TGraphic): Boolean;
begin
  // PNG: alpha channel is preserved as-is
  // PNG: альфа-канал сохраняется как есть
  if TryLoadPNG(Graphic) then
    exit(True);

  // CF_DIBV5: manual parsing of 32-bit data with alpha
  // CF_DIBV5: ручной разбор 32-битных данных с альфой
  if TryLoadDIBV5(Graphic) then
    exit(True);

  // Standard VCL: alpha will be lost
  // Стандартный VCL: альфа будет потеряна (но это не точно :))
  if TryLoadVCL(Graphic) then
    exit(True);

  Graphic := nil;
  Result := False;
end;

{$EndRegion}

{$Region 'Helper functions (saving to clipboard)'}
// Вспомогательные функции (сохранение в буфер)

// Converts an arbitrary TGraphic to a 32-bit TBitmap with alpha channel.
// If input Graphic is already TBitmap pf32bit - copies as-is.
// If TPngImage - uses Assign to preserve alpha.
// For others - draws on canvas, alpha will be 255 (opaque).
//
// Конвертирует произвольный TGraphic в 32-битный TBitmap с альфа-каналом.
// Если входной Graphic уже TBitmap pf32bit - копирует как есть.
// Если TPngImage - использует Assign для сохранения альфы.
// Для остальных - рисует на канве, альфа будет 255 (непрозрачный).
function GraphicTo32Bitmap(Graphic: TGraphic): TBitmap;
begin
  Result := TBitmap.Create;
  try
    if Graphic is TBitmap then
      Result.Assign(Graphic)
    else if Graphic is TPngImage then
      // Assign from TPngImage preserves alpha channel
      // Assign из TPngImage сохраняет альфа-канал
      Result.Assign(Graphic)
    else
    begin
      // Arbitrary TGraphic - draw on canvas, alpha = 255
      // Произвольный TGraphic - рисуем на канве, альфа = 255
      Result.PixelFormat := pf32bit;
      Result.SetSize(Graphic.Width, Graphic.Height);
      Result.Canvas.Draw(0, 0, Graphic);
      FillAlpha(Result.ScanLine[Result.Height - 1],
        Result.Width * Result.Height);
    end;
    // If already pf32bit, this is a no-op
    // Если уже pf32bit, ничего не произойдёт
    Result.PixelFormat := pf32bit;
  except
    Result.Free;
    raise;
  end;
end;

// Places a data block into clipboard as the specified format.
// Clipboard must be already opened (Clipboard.Open).
// Помещает блок данных в буфер обмена как указанный формат.
// Буфер должен быть уже открыт (Clipboard.Open).
function SetClipboardData(AFormat: Word; Data: Pointer; Size: NativeUInt): Boolean;
var H: THandle; Ptr: Pointer;
begin
  Result := False;

  H := GlobalAlloc(GMEM_MOVEABLE, Size);
  if H = 0 then
    exit;

  Ptr := GlobalLock(H);
  if Ptr = nil then
  begin
    GlobalFree(H);
    exit;
  end;

  try
    Move(Data^, Ptr^, Size);
  finally
    GlobalUnlock(H);
  end;

  // After SetClipboardData the system owns the memory - do not free
  // После SetClipboardData система владеет памятью - не освобождаем
  if Winapi.Windows.SetClipboardData(AFormat, H) = 0 then
  begin
    GlobalFree(H);
    exit;
  end;

  Result := True;
end;

// Checks whether a bitmap contains a meaningful alpha channel
// (has both transparent and opaque pixels, or semi-transparent ones).
// Проверяет, содержит ли битмап осмысленный альфа-канал
// (есть и прозрачные, и непрозрачные пиксели, или полупрозрачные).
function CheckBitmapAlpha(const ABitmap: TBitmap): Boolean;
var
  I, Total: Integer;
  P: PRGBQuad;
  HasTransparent, HasOpaque: Boolean;
begin
  if not (Assigned(ABitmap) and (ABitmap.PixelFormat = pf32bit)) then
    exit(False);

  Total := ABitmap.Width * ABitmap.Height;
  if Total = 0 then
    exit(False);

  P := ABitmap.ScanLine[ABitmap.Height - 1];
  HasTransparent := False;
  HasOpaque := False;

  for I := 0 to Total - 1 do
  begin
    if (P^.rgbReserved > 0) and (P^.rgbReserved < 255) then
      exit(True);

    if P^.rgbReserved = 0 then
    begin
      if HasOpaque then
        exit(True);
      HasTransparent := True;
    end
    else if P^.rgbReserved = 255 then
    begin
      if HasTransparent then
        exit(True);
      HasOpaque := True;
    end;

    Inc(P);
  end;

  Result := False;
end;

// Convert TBitmap to TPNGImage preserving the alpha channel
// Конвертировать TBitmap в TPNGImage с переносом альфа-канала
function BitmapToPNG(ABitmap: TBitmap): TPNGImage;
var
  V: PByte;
  P: PRGBQuad;
  X, Y, W, H: Integer;
  Tmp: TBitmap;
begin
  if ABitmap = nil then
    exit(nil);

  W := ABitmap.Width;
  H := ABitmap.Height;

  if (W = 0) or (H = 0) then
    exit(nil);

  Result := TPNGImage.Create;
  try
    if (ABitmap.AlphaFormat <> afIgnored) and CheckBitmapAlpha(ABitmap) then
    begin
      // Create a clone to avoid corrupting original data
      // Чтобы не портить данные, создаём клон
      Tmp := TBitmap.Create;
      try
        Tmp.Assign(ABitmap);
        // Restore clone data to its original (non-premultiplied) state
        // Возвращаем данные клона в первозданный вид
        Tmp.AlphaFormat := afIgnored;
        Result.Assign(Tmp);
        Result.CreateAlpha;
        if Result.AlphaScanline[0] = nil then
          exit;
        // Copy the alpha channel
        // Переписыаем альфа-канал
        P := ABitmap.ScanLine[H - 1];
        for Y := H - 1 downto 0 do
        begin
          V := @Result.AlphaScanline[Y]^[0];
          for X := 0 to W - 1 do
          begin
            V^ := P^.rgbReserved;
            Inc(P);
            Inc(V);
          end;
        end;
      finally
        Tmp.Free;
      end;
    end
    else
      Result.Assign(ABitmap);
  except
    FreeAndNil(Result);
    raise;
  end;
end;


{$EndRegion}

{$Region 'Saving to clipboard'}
// Сохранение в буфер обмена

// Save as PNG
// Сохранение PNG
function TrySavePNG(Graphic: TGraphic): Boolean;
var S: TMemoryStream; Png: TPngImage; IsBitmap: Boolean;
begin
  Result := False;

  if CF_PNG = 0 then
    exit;

  IsBitmap := Graphic is TBitmap;

  if IsBitmap then
    Png := BitmapToPNG(TBitmap(Graphic))
  else
    Png := TPngImage.Create;

  if Png = nil then
    exit;

  try
    if not IsBitmap then
      Png.Assign(Graphic);

    S := TMemoryStream.Create;
    try
      Png.SaveToStream(S);

      Clipboard.Open;
      try
        Result := SetClipboardData(CF_PNG, S.Memory, S.Size);
      finally
        Clipboard.Close;
      end;
    finally
      S.Free;
    end;
  finally
    Png.Free;
  end;
end;

// Save as CF_DIBV5
// Сохранение CF_DIBV5
function TrySaveDIBV5(Graphic: TGraphic): Boolean;
var
  Bmp: TBitmap;
  Header: TBITMAPV5HEADER;
  Width, Height: Integer;
  RowSize: Integer;
  DataSize: NativeUInt;
  Buffer: TMemoryStream;
  Y: Integer;
  SrcRow: PByte;
begin
//  Result := False;

  Bmp := GraphicTo32Bitmap(Graphic);
  try
    Width := Bmp.Width;
    Height := Bmp.Height;
    RowSize := Width * 4;

    // Build the header
    // Формируем заголовок
    FillChar(Header, SizeOf(Header), 0);
    Header.bV5Size := SizeOf(TBITMAPV5HEADER);
    Header.bV5Width := Width;
      // top-down - rows from top to bottom
      // top-down - строки сверху вниз
    Header.bV5Height := -Height;
    Header.bV5Planes := 1;
    Header.bV5BitCount := 32;
    Header.bV5Compression := BI_BITFIELDS;
    Header.bV5SizeImage := RowSize * Height;
    Header.bV5RedMask   := $00FF0000;
    Header.bV5GreenMask := $0000FF00;
    Header.bV5BlueMask  := $000000FF;
    Header.bV5AlphaMask := $FF000000;
    Header.bV5CSType := $73524742; // 'sRGB'
    // Header.bV5CSType := $57696E20; // 'Win' - neutral option
    Header.bV5Intent := LCS_GM_IMAGES;

    DataSize := SizeOf(Header) + NativeUInt(RowSize) * NativeUInt(Height);

    Buffer := TMemoryStream.Create;
    try
      Buffer.SetSize(DataSize);

      // Write the header
      // Пишем заголовок
      Move(Header, Buffer.Memory^, SizeOf(Header));

      // Write pixel rows (top-down - direct order)
      // Пишем пиксельные строки (top-down - прямой порядок)
      for Y := 0 to Height - 1 do
      begin
        SrcRow := Bmp.ScanLine[Y];
        Move(SrcRow^, PByte(PByte(Buffer.Memory) +
          SizeOf(Header) + NativeUInt(Y) * NativeUInt(RowSize))^, RowSize);
      end;

      Clipboard.Open;
      try
        Result := SetClipboardData(CF_DIBV5, Buffer.Memory, DataSize);
      finally
        Clipboard.Close;
      end;
    finally
      Buffer.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

// Save via standard VCL
// Сохранение через стандартный VCL
function TrySaveVCL(Graphic: TGraphic): Boolean;
begin
  Result := False;
  try
    Clipboard.Assign(Graphic);
    Result := True;
  except
    // Silent catch - this is the last resort fallback
    // If this also fails, just return False
    // Тут молчим, это последний резерв
    // Если и здесь упало, просто возвращаем False
  end;
end;

// Cascading save
// Каскадное сохранение
function TrySaveGraphicToClipboard(Graphic: TGraphic): Boolean;
var SavedPNG, SavedDIBV5: Boolean;
begin
  if (Graphic = nil) or Graphic.Empty then
    exit(False);

  // Clear clipboard once before writing all formats
  // Очищаем буфер один раз перед записью всех форматов
  Clipboard.Open;
  try
    Clipboard.Clear;
  finally
    Clipboard.Close;
  end;

  // Place both formats - each for its own consumers
  // Кладём оба формата - каждый для своих потребителей
  SavedPNG := TrySavePNG(Graphic);
  SavedDIBV5 := TrySaveDIBV5(Graphic);

  // Sufficient if at least one format was placed successfully.
  // CF_DIB and CF_BITMAP are synthesized by Windows from CF_DIBV5 automatically.
  // Достаточно, если хотя бы один формат лёг успешно.
  // CF_DIB и CF_BITMAP Windows синтезирует из CF_DIBV5 автоматически.
  if SavedPNG or SavedDIBV5 then
    exit(True);

  Result := TrySaveVCL(Graphic);
end;

{$EndRegion}

{$Region 'Text clipboard'}
// Текстовый буфер обмена

function TrySaveStringToClipboard(const Value: string): Boolean;
var DataSize: NativeUInt;
begin
  // +1: завершающий #0 обязателен для CF_UNICODETEXT.
  DataSize := (NativeUInt(Length(Value)) + 1) * SizeOf(WideChar);

  Clipboard.Open;
  try
    // Здесь намеренно НЕ вызывается Clipboard.Clear:
    // PNG, CF_DIBV5 и прочие уже имеющиеся форматы должны сохраниться
    Result := SetClipboardData(
      CF_UNICODETEXT,
      PWideChar(Value),
      DataSize
    );
  finally
    Clipboard.Close;
  end;
end;

function TryLoadStringFromClipboard(out Value: string): Boolean;
var
  Stream: TMemoryStream;
  P: PWideChar;
  CharCount, I: NativeUInt;
begin
  Result := False;
  Value := '';

  Stream := GetClipboardStream(CF_UNICODETEXT);
  if Stream = nil then
    exit;

  try
    // CF_UNICODETEXT должен содержать целое число WideChar и завершающий ноль
    if (Stream.Size < SizeOf(WideChar)) or
       ((Stream.Size mod SizeOf(WideChar)) <> 0) then
      exit;

    P := PWideChar(Stream.Memory);
    CharCount := Stream.Size div SizeOf(WideChar);

    // Не предполагаем, что повреждённые данные обязательно содержат #0
    for I := 0 to CharCount - 1 do
      if P[I] = #0 then
      begin
        SetString(Value, P, I);
        Result := True;
        exit;
      end;
  finally
    Stream.Free;
  end;
end;

{$EndRegion}

{$Region 'Initialization'}
// Инициализация

initialization
  CF_PNG := RegisterClipboardFormat('PNG');

{$EndRegion}

end.
