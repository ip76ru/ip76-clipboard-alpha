program ip76ClipboardDemo;

uses
  Vcl.Forms,
  UnMain in 'UnMain.pas' {FmMain},
  IP76.Imaging.Clipbrd in 'IP76.Imaging.Clipbrd.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
