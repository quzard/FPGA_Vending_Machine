program BmpToMif;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  Lib in 'Lib.pas',
  ABOUT in 'ABOUT.pas' {AboutBox},
  PreView in 'PreView.pas' {FormPreView};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'PicToMif';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TFormPreView, FormPreView);
  Application.Run;
end.
