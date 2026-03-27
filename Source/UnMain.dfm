object FmMain: TFmMain
  Left = 0
  Top = 0
  Caption = 'FmMain'
  ClientHeight = 399
  ClientWidth = 851
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 281
    Top = 0
    Height = 376
    MinSize = 130
    ExplicitLeft = 282
    ExplicitTop = -6
    ExplicitHeight = 390
  end
  object Panel2: TPanel
    Left = 0
    Top = 376
    Width = 851
    Height = 23
    Align = alBottom
    BevelOuter = bvNone
    BorderWidth = 1
    Caption = ' '
    TabOrder = 0
    object Label6: TLabel
      Left = 704
      Top = 1
      Width = 146
      Height = 21
      Cursor = crHandPoint
      Align = alRight
      Caption = '        Read more on IP76.RU...'
      Layout = tlCenter
      OnClick = Label6Click
      ExplicitHeight = 13
    end
    object Label1: TLabel
      Left = 1
      Top = 1
      Width = 24
      Height = 21
      Cursor = crHandPoint
      Align = alLeft
      Caption = '        '
      Layout = tlCenter
      ExplicitHeight = 13
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 281
    Height = 376
    Align = alLeft
    BevelKind = bkFlat
    BevelOuter = bvNone
    BorderWidth = 3
    Caption = ' '
    Constraints.MinWidth = 140
    TabOrder = 1
    object Panel4: TPanel
      Left = 3
      Top = 3
      Width = 271
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      BorderWidth = 3
      Caption = ' '
      TabOrder = 0
      object btnRefresh: TButton
        Left = 193
        Top = 3
        Width = 75
        Height = 26
        Align = alRight
        Caption = 'Refresh'
        TabOrder = 0
        OnClick = btnRefreshClick
      end
    end
    object ListView1: TListView
      Left = 3
      Top = 35
      Width = 271
      Height = 334
      Align = alClient
      Columns = <>
      GridLines = True
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
      OnSelectItem = ListView1SelectItem
    end
  end
  object Panel3: TPanel
    Left = 284
    Top = 0
    Width = 567
    Height = 376
    Align = alClient
    BevelKind = bkFlat
    BevelOuter = bvNone
    BorderWidth = 3
    Caption = ' '
    TabOrder = 2
    object Panel5: TPanel
      Left = 3
      Top = 3
      Width = 557
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      BorderWidth = 3
      Caption = ' '
      TabOrder = 0
      object btnIP76Paste: TButton
        Left = 78
        Top = 3
        Width = 75
        Height = 26
        Align = alLeft
        Caption = 'IP76.Paste'
        TabOrder = 1
        OnClick = btnIP76PasteClick
      end
      object btnIP76Copy: TButton
        Left = 3
        Top = 3
        Width = 75
        Height = 26
        Align = alLeft
        Caption = 'IP76.Copy'
        TabOrder = 0
        OnClick = btnIP76CopyClick
      end
      object btnVCLPaste: TButton
        Left = 479
        Top = 3
        Width = 75
        Height = 26
        Align = alRight
        Caption = 'VCL.Paste'
        TabOrder = 3
        OnClick = btnVCLPasteClick
      end
      object btnVCLCopy: TButton
        Left = 404
        Top = 3
        Width = 75
        Height = 26
        Align = alRight
        Caption = 'VCL.Copy'
        TabOrder = 2
        OnClick = btnVCLCopyClick
      end
    end
    object Panel6: TPanel
      Left = 3
      Top = 35
      Width = 557
      Height = 334
      Align = alClient
      BevelKind = bkFlat
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 1
      object pb: TPaintBox
        Left = 0
        Top = 0
        Width = 553
        Height = 330
        Align = alClient
        OnPaint = pbPaint
        ExplicitLeft = 128
        ExplicitTop = 120
        ExplicitWidth = 105
        ExplicitHeight = 105
      end
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 553
        Height = 330
        Align = alClient
        ExplicitLeft = 1
        ExplicitTop = 35
        ExplicitWidth = 469
        ExplicitHeight = 348
      end
    end
  end
end
