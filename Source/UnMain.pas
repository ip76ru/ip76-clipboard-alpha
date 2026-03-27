//******************************************************************************
//  Project: IP76.RU
//  Created: 2026-02-12
//  Article: https://ip76.ru/clipbrd-alpha/
//  Description: Clipboard image exchange without losing the alpha channel
//  Описание: Обмен изображениями через буфер обмена без потери альфа-канала
//******************************************************************************

unit UnMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellApi,
  System.SysUtils, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Imaging.jpeg, Vcl.Imaging.PNGImage, Vcl.Imaging.GIFImg;

type
  TFmMain = class(TForm)
    Panel2: TPanel;
    Label6: TLabel;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    ListView1: TListView;
    Label1: TLabel;
    Panel6: TPanel;
    Image1: TImage;
    pb: TPaintBox;
    btnIP76Paste: TButton;
    btnIP76Copy: TButton;
    btnVCLPaste: TButton;
    btnVCLCopy: TButton;
    btnRefresh: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ControlEnterEvent(Sender: TObject);
    procedure ControlLeaveEvent(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure pbPaint(Sender: TObject);
    procedure btnIP76PasteClick(Sender: TObject);
    procedure btnIP76CopyClick(Sender: TObject);
    procedure Label6Click(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnVCLCopyClick(Sender: TObject);
    procedure btnVCLPasteClick(Sender: TObject);
  private
    // Set hint for a control
    // Устанавливаем хинт контролу
    procedure InitHintControls(AControl: TControl; const AHint: string);
    // Set mouse hover events
    // Устанавливаем события наведения мышью
    procedure InitMouseEventControl(AControl: TControl);
  private
    FFormatList: TList;
    // Configure ListView columns
    // Настройка колонок ListView
    procedure SetupColumns;
    // Clear the format list
    // Очистка списка форматов
    procedure ClearFormatList;
    // Enumerates all formats currently present in the clipboard
    // Перечисляет все форматы, присутствующие в буфере обмена
    procedure EnumerateClipboard;
  private
    // Display status in the status label
    // Отображение статуса в строке состояния
    procedure ShowStatus(const S: string);
  end;

var
  FmMain: TFmMain;

implementation

uses
  Vcl.Clipbrd, IP76.Imaging.Clipbrd;

{$R *.dfm}

{$Region 'Clipboard formats'}
// Форматы буфера обмена

type
  PClipFormatInfo = ^TClipFormatInfo;
  TClipFormatInfo = record
    FormatID: Cardinal;
    FormatName: string;
    DataSize: Cardinal;
  end;

const
  StandardFormatNames: array[1..17] of record
    ID: Word;
    Name: string;
  end = (
    (ID: 1;  Name: 'CF_TEXT'),
    (ID: 2;  Name: 'CF_BITMAP'),
    (ID: 3;  Name: 'CF_METAFILEPICT'),
    (ID: 4;  Name: 'CF_SYLK'),
    (ID: 5;  Name: 'CF_DIF'),
    (ID: 6;  Name: 'CF_TIFF'),
    (ID: 7;  Name: 'CF_OEMTEXT'),
    (ID: 8;  Name: 'CF_DIB'),
    (ID: 9;  Name: 'CF_PALETTE'),
    (ID: 10; Name: 'CF_PENDATA'),
    (ID: 11; Name: 'CF_RIFF'),
    (ID: 12; Name: 'CF_WAVE'),
    (ID: 13; Name: 'CF_UNICODETEXT'),
    (ID: 14; Name: 'CF_ENHMETAFILE'),
    (ID: 15; Name: 'CF_HDROP'),
    (ID: 16; Name: 'CF_LOCALE'),
    (ID: 17; Name: 'CF_DIBV5')
  );

// Returns the name of a standard clipboard format by its ID
// Возвращает имя стандартного формата буфера обмена по его ID
function GetStandardFormatName(Fmt: Cardinal): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(StandardFormatNames) to High(StandardFormatNames) do
    if StandardFormatNames[I].ID = Fmt then
      exit(StandardFormatNames[I].Name);
end;

// Formats byte size into a human-readable string
// Форматирует размер в байтах в человекочитаемый вид
function FormatByteSize(Bytes: Cardinal): string;
begin
  if Bytes = 0 then
    Result := '-'
  else if Bytes < 1024 then
    Result := Format('%d B', [Bytes])
  else if Bytes < 1024 * 1024 then
    Result := Format('%.1f KB', [Bytes / 1024])
  else
    Result := Format('%.2f MB', [Bytes / (1024 * 1024)]);
end;

{$EndRegion}

{$Region 'Loading image from clipboard (demo)'}
// Попытки получить изображение из буфера (для демо)

// Load via standard VCL preserving the original graphic type
// Загрузка через стандартный VCL с сохранением оригинального типа графики
function TryLoadPicture(out Graphic: TGraphic): Boolean;
var Pic: TPicture;
begin
  Result := False;
  Graphic := nil;

  Pic := TPicture.Create;
  try
    try
      Pic.Assign(Clipboard);
      if Pic.Graphic <> nil then
      begin
        // Create a copy because Pic owns its Graphic
        // Создаём копию, потому что Pic владеет своим Graphic
        Graphic := TGraphicClass(Pic.Graphic.ClassType).Create;
        Graphic.Assign(Pic.Graphic);
        Result := True;
      end;
    except
      FreeAndNil(Graphic);
    end;
  finally
    Pic.Free;
  end;
end;

{$EndRegion}

procedure TFmMain.FormCreate(Sender: TObject);
begin
  Caption := 'IP76.RU: Clipboard Demo';

  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;

  InitHintControls(Label6, 'https://ip76.ru/clipbrd-alpha/');
  InitHintControls(btnVCLPaste, 'VCL Paste image from clipboard (Ctrl+V)');
  InitHintControls(btnVCLCopy, 'VCL Copy image to clipboard (Ctrl+C)');
  InitHintControls(btnIP76Paste, 'IP76 Paste image from clipboard (Ctrl+Shift+V)');
  InitHintControls(btnIP76Copy, 'IP76 Copy image to clipboard (Ctrl+Shift+C)');
  InitHintControls(btnRefresh, 'Refresh list');

  FFormatList := TList.Create;

  ListView1.ViewStyle := vsReport;
  ListView1.RowSelect := True;
  ListView1.ReadOnly := True;
  ListView1.GridLines := True;
  ListView1.HideSelection := False;

  SetupColumns;

  Image1.Stretch := True;
  Image1.Proportional := True;
  Image1.Center := True;
end;

procedure TFmMain.FormDestroy(Sender: TObject);
begin
  ClearFormatList;
  FFormatList.Free;
end;

procedure TFmMain.FormShow(Sender: TObject);
begin
  btnRefresh.Click;
end;

// Opens URL from hint on label click
// Открывает URL из хинта по клику на лейбл
procedure TFmMain.Label6Click(Sender: TObject);
begin
  if TControl(Sender).Hint <> '' then
    ShellExecute(Handle, 'open', PChar(TControl(Sender).Hint), nil, nil, SW_NORMAL);
end;

// Keyboard shortcut handler
// Обработка горячих клавиш
procedure TFmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssCtrl in Shift then
    case Char(Key) of
      'C': if ssShift in Shift then btnIP76Copy.Click else btnVCLCopy.Click;
      'V': if ssShift in Shift then btnIP76Paste.Click else btnVCLPaste.Click;
    end;
end;

// Set hint and mouse hover events for a control
// Устанавливаем хинт и события наведения мышью
procedure TFmMain.InitHintControls(AControl: TControl; const AHint: string);
begin
  AControl.ShowHint := True;
  AControl.Hint := AHint;
  InitMouseEventControl(AControl);
end;

type
  TControlAccess = class(TControl);

// Set mouse enter/leave events for a control
// Устанавливаем события наведения мышью
procedure TFmMain.InitMouseEventControl(AControl: TControl);
begin
  TControlAccess(AControl).OnMouseEnter := ControlEnterEvent;
  TControlAccess(AControl).OnMouseLeave := ControlLeaveEvent;
end;

// Highlight control on mouse enter
// Подсветка контрола при наведении мыши
procedure TFmMain.ControlEnterEvent(Sender: TObject);
begin
  if (Sender is TLabel) and (TLabel(Sender).Hint='') then
    exit;
  TControlAccess(Sender).Font.Color := clHighlight;
  TControl(Sender).Cursor := crHandPoint;
end;

// Reset control highlight on mouse leave
// Сброс подсветки контрола при уходе мыши
procedure TFmMain.ControlLeaveEvent(Sender: TObject);
begin
  if Sender is TSpeedButton then
    TControlAccess(Sender).Font.Color := clGrayText
  else
    TControlAccess(Sender).Font.Color := clWindowText;
  TControl(Sender).Cursor := crDefault;
end;

procedure TFmMain.ShowStatus(const S: string);
begin
  Label1.Caption := S;
end;

procedure TFmMain.SetupColumns;
  procedure AddColumn(const ACaption: string; AWidth: Integer; AAlignment: TAlignment = taLeftJustify);
  begin
    with ListView1.Columns.Add do
    begin
      Caption := ACaption;
      Width := AWidth;
      Alignment := AAlignment;
    end;
  end;
begin
  ListView1.Columns.Clear;
  AddColumn('#', 35, taCenter);
  AddColumn('ID', 60, taRightJustify);
  AddColumn('Format', 200);
  AddColumn('Size', 100, taRightJustify);
  AddColumn('Type', 120);
end;

// Refresh clipboard format list
// Обновление списка форматов буфера обмена
procedure TFmMain.btnRefreshClick(Sender: TObject);
begin
  EnumerateClipboard;
end;

// Paste from clipboard via IP76.Imaging.Clipbrd (preserving alpha channel)
// Вставка из буфера через IP76.Imaging.Clipbrd (с сохранением альфа-канала)
procedure TFmMain.btnIP76PasteClick(Sender: TObject);
var G: TGraphic;
begin
  if TryLoadGraphicFromClipboard(G) then
    try
      Image1.Picture.Assign(G);
    finally
      G.Free;
    end
  else
  begin
    Image1.Picture.Graphic := nil;
    MessageDlg('Failed to load image from clipboard',
       mtError, [mbOk], 0);
  end;
end;

// Copy to clipboard via IP76.Imaging.Clipbrd (preserving alpha channel)
// Копирование в буфер через IP76.Imaging.Clipbrd (с сохранением альфа-канала)
procedure TFmMain.btnIP76CopyClick(Sender: TObject);
begin
  if not TrySaveGraphicToClipboard(Image1.Picture.Graphic) then
    MessageDlg('Failed to paste image to clipboard',
      mtError, [mbOk], 0);
end;

// Copy to clipboard via standard VCL
// Копирование в буфер через стандартный VCL
procedure TFmMain.btnVCLCopyClick(Sender: TObject);
begin
  Clipboard.Assign(Image1.Picture);
  btnRefresh.Click;
end;

// Paste from clipboard via standard VCL
// Вставка из буфера через стандартный VCL
procedure TFmMain.btnVCLPasteClick(Sender: TObject);
begin
  Image1.Picture.Assign(Clipboard);
end;

// Draws a chessboard background to visualize transparency
// Рисует шахматный фон для визуализации прозрачности
procedure DrawChessboard(
  ACanvas: TCanvas; const ARect: TRect;
  Size: Integer = 8;
  Light: TColor = clSilver;
  Dark: TColor = clGray);
var Pattern: TBitmap;
begin
  Pattern := TBitmap.Create;
  try
    Pattern.SetSize(2*Size, 2*Size);
    Pattern.PixelFormat := pf24bit;

    with Pattern.Canvas do
    begin
      Brush.Style := bsSolid;
      // Draw four pattern cells
      // Рисуем четыре клетки паттерна
      Brush.Color := Light;
      FillRect(Rect(0,0,Size,Size));
      FillRect(Rect(Size,Size,2*Size,2*Size));

      Brush.Color := Dark;
      FillRect(Rect(Size, 0, 2*Size, Size));
      FillRect(Rect(0, Size, Size, 2*Size));
    end;
    // Assign pattern to brush
    // Назначаем паттерн кисти
    ACanvas.Brush.Bitmap := Pattern;
    // Fill rectangle with pattern
    // Рисуем прямоугольник паттерном
    ACanvas.FillRect(ARect);
    // Clear brush (important!)
    // Очищаем кисть (важно!)
    ACanvas.Brush.Bitmap := nil;
  finally
    Pattern.Free;
  end;
end;

procedure TFmMain.pbPaint(Sender: TObject);
begin
  DrawChessboard(pb.Canvas, pb.Canvas.ClipRect);
end;

procedure TFmMain.ClearFormatList;
var I: Integer;
begin
  for I := 0 to FFormatList.Count - 1 do
    Dispose(PClipFormatInfo(FFormatList[I]));
  FFormatList.Clear;
end;

// Safely retrieves the data size of a clipboard format
// Безопасно получает размер данных формата в буфере обмена
function SafeGetClipboardDataSize(Fmt: Cardinal): Cardinal;
var Handle: THandle;
begin
  Result := 0;

  // These formats return GDI handles, not HGLOBAL
  // Эти форматы возвращают GDI-хэндлы, а не HGLOBAL
  if Fmt in [CF_BITMAP, CF_PALETTE, CF_ENHMETAFILE, CF_METAFILEPICT,
    CF_DSPBITMAP, CF_DSPENHMETAFILE, CF_DSPMETAFILEPICT] then
    exit;

  Handle := GetClipboardData(Fmt);
  if Handle = 0 then
    exit;

  // Extra safety: GlobalSize returns 0 for invalid handles,
  // but may crash - wrap in try/except
  // Дополнительная проверка: GlobalSize возвращает 0 для невалидных хэндлов,
  // но может и упасть - оборачиваем в try/except
  try
    Result := GlobalSize(Handle);
  except
    Result := 0;
  end;
end;

procedure TFmMain.EnumerateClipboard;
var
  Fmt: Cardinal;
  Buf: array[0..255] of Char;
  Info: PClipFormatInfo;
  Item: TListItem;
  Index: Integer;
  FormatType: string;
begin
  ClearFormatList;
  ListView1.Items.Clear;

  if not OpenClipboard(0) then
  begin
    Item := ListView1.Items.Add;
    Item.Caption := '!';
    Item.SubItems.Add('');
    Item.SubItems.Add('Failed to open clipboard');
    exit;
  end;

  try
    Index := 0;
    Fmt := 0;
    repeat
      Fmt := EnumClipboardFormats(Fmt);
      if Fmt <> 0 then
      begin
        Inc(Index);

        New(Info);
        Info^.FormatID := Fmt;

        // Format name / Имя формата
        Info^.FormatName := GetStandardFormatName(Fmt);
        if Info^.FormatName = '' then
        begin
          FillChar(Buf, SizeOf(Buf), 0);
          if GetClipboardFormatName(Fmt, Buf, Length(Buf)) > 0 then
            Info^.FormatName := Buf
          else
            Info^.FormatName := Format('Unknown_%d', [Fmt]);
        end;

        // Data size / Размер данных
        Info^.DataSize := SafeGetClipboardDataSize(Fmt);

        // Determine type / Определяем тип
        if Fmt = CF_BITMAP then
          FormatType := 'Bitmap (HBITMAP)'
        else if Fmt = CF_PALETTE then
          FormatType := 'Palette (HPALETTE)'
        else if Fmt = CF_ENHMETAFILE then
          FormatType := 'Metafile (HEMF)'
        else if Fmt = CF_METAFILEPICT then
          FormatType := 'Metafile (HMETA)'
        else if Info^.FormatName = 'PNG' then
          FormatType := 'Bitmap (PNG)'
        else if Fmt = CF_DIBV5 then
          FormatType := 'Bitmap (DIBv5)'
        else if Fmt = CF_DIB then
          FormatType := 'Bitmap (DIB)'
        else if Fmt in [CF_TEXT, CF_OEMTEXT, CF_UNICODETEXT] then
          FormatType := 'Text'
        else
          FormatType := 'Other';
        FFormatList.Add(Info);

        // Add row to ListView / Добавляем строку в ListView
        Item := ListView1.Items.Add;
        Item.Caption := IntToStr(Index);
        Item.SubItems.Add(IntToStr(Info^.FormatID));
        Item.SubItems.Add(Info^.FormatName);
        Item.SubItems.Add(FormatByteSize(Info^.DataSize));
        Item.SubItems.Add(FormatType);
        Item.Data := Info; // link row to data / связь строки с данными
      end;
    until Fmt = 0;
  finally
    CloseClipboard;
  end;
end;

// Handle format selection in the list - load and display image
// Обработка выбора формата в списке - загрузка и отображение изображения
procedure TFmMain.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Info: PClipFormatInfo;
  Graphic: TGraphic;
  Method: string;
  AlphaInfo: string;
begin
  if not Selected then exit;
  if (Item=nil) or (Item.Data=nil) then exit;

  Info := PClipFormatInfo(Item.Data);
  Graphic := nil;
  Method := '';

  // Cascade: PNG - CF_DIBV5 - TPicture
  // Каскад: PNG - CF_DIBV5 - TPicture
  if (Info^.FormatName = 'PNG') and TryLoadPNG(Graphic) then
    Method := 'PNG'
  else if (Info^.FormatID = CF_DIBV5) and TryLoadDIBV5(Graphic) then
    Method := 'CF_DIBV5'
  else if (Info^.FormatID in [CF_BITMAP, CF_DIB, CF_DIBV5]) and TryLoadPicture(Graphic) then
    Method := 'TPicture'
  else
  begin
    ShowStatus(Format('Format "%s" - failed to extract image',
      [Info^.FormatName]));
    Image1.Picture.Graphic := nil;
    exit;
  end;

  try
    Image1.Picture.Graphic := Graphic;

    // Determine alpha channel information
    // Определяем информацию об альфе
    if Graphic is TPngImage then
    begin
      case TPngImage(Graphic).Header.ColorType of
        COLOR_RGBALPHA:       AlphaInfo := 'RGBA (alpha present)';
        COLOR_GRAYSCALEALPHA: AlphaInfo := 'GrayAlpha (alpha present)';
      else
        AlphaInfo := 'no alpha';
      end;
    end
    else if Graphic is TBitmap then
    begin
      if TBitmap(Graphic).PixelFormat = pf32bit then
        if TBitmap(Graphic).AlphaFormat = afIgnored then
          AlphaInfo := '32bit (alpha empty)'
        else
          AlphaInfo := '32bit (alpha present)'
      else
        AlphaInfo := Format('%dbit', [GetDeviceCaps(0, BITSPIXEL)]);
    end
    else
      AlphaInfo := Graphic.ClassName;

    ShowStatus(Format('%s | %dx%d | %s',
      [Method, Graphic.Width, Graphic.Height, AlphaInfo]));
  finally
    Graphic.Free;
  end;
end;

end.
