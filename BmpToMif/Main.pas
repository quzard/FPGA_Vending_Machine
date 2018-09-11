{
  PicToMif
  Author: Yao Chunhui & Zhou Xintong
  IDE: Borland Developer Studio 2006 (Delphi)
  Copyright @ 2006 Laputa Develop Group
  July 16th, 2006

  PicToMif is a freeware, which can be used to convert
  bitmap or binary files to QuartusII memory initialization
  files. It can be spread freely, as long as not being used
  in commerce.
}

unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, RzTabs, Lib, ComCtrls, Spin, ExtDlgs, Menus,
  About, PreView;

type
  TFormMain = class(TForm)
    RzPageControl: TRzPageControl;
    TabSheetBmp: TRzTabSheet;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    ScrollBoxPic: TScrollBox;
    ImagePic: TImage;
    TabSheetBinary: TRzTabSheet;
    BtnLoadFile: TButton;
    EditFile: TEdit;
    GroupBoxBoundary: TGroupBox;
    PanelColor: TPanel;
    LabelRed: TLabel;
    EditRed: TEdit;
    EditGreen: TEdit;
    LabelGreen: TLabel;
    EditBlue: TEdit;
    LabelBlue: TLabel;
    TrackBarRed: TTrackBar;
    TrackBarGreen: TTrackBar;
    TrackBarBlue: TTrackBar;
    mmoLog: TMemo;
    Label1: TLabel;
    seLen: TSpinEdit;
    Label3: TLabel;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    ButtonMake: TButton;
    ButtonLoad: TButton;
    LabelSize: TLabel;
    GroupBoxType: TGroupBox;
    RadioButtonTypeBlack: TRadioButton;
    RadioButtonTypeColor: TRadioButton;
    GroupBoxColor: TGroupBox;
    RadioButtonColorSingle: TRadioButton;
    RadioButtonColorMultiple: TRadioButton;
    GroupBoxBlack: TGroupBox;
    RadioButtonBlack: TRadioButton;
    RadioButtonWhite: TRadioButton;
    ColorDialog1: TColorDialog;
    MainMenu1: TMainMenu;
    M1: TMenuItem;
    mExit: TMenuItem;
    A1: TMenuItem;
    N1: TMenuItem;
    Button1: TButton;
    ButtonPreView: TButton;
    ButtonColorReset: TButton;
    TabSheet1: TRzTabSheet;
    mmoHelp: TMemo;
    procedure ButtonColorResetClick(Sender: TObject);
    procedure ButtonPreViewClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure A1Click(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure ScrollBoxPicDblClick(Sender: TObject);
    procedure RadioButtonTypeColorClick(Sender: TObject);
    procedure RadioButtonTypeBlackClick(Sender: TObject);
    procedure TrackBarBlueChange(Sender: TObject);
    procedure TrackBarGreenChange(Sender: TObject);
    procedure TrackBarRedChange(Sender: TObject);
    procedure EditRedGreenBlueChange(Sender: TObject);
    procedure btnBinToMifClick(Sender: TObject);
    procedure BtnLoadFileClick(Sender: TObject);
    procedure ButtonMakeClick(Sender: TObject);
    procedure ButtonLoadClick(Sender: TObject);
  private
    { Private declarations }

    PicFile: string;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.Button1Click(Sender: TObject);
var
  w, h: Integer;
  I, J: Integer;
  br, bg, bb: TBitmap;
  blue, green, red: Integer;
  color: TColor;
begin
  w := ImagePic.Picture.Width;
  h := ImagePic.Picture.Height;
  br := TBitmap.Create;
  bg := TBitmap.Create;
  bb := TBitmap.Create;
  br.SetSize(w, h);
  bg.SetSize(w, h);
  bb.SetSize(w, h);
  for I := 0 to w - 1 do
    for J := 0 to h - 1 do
    begin
      color := ImagePic.Picture.Bitmap.Canvas.Pixels[I, J];
      blue := color shr 16;
      green := (color and ($0000FF00)) shr 8;
      red := color and $000000FF;
      if red > TrackBarRed.Position then
          br.Canvas.Pixels[I, J] := clRed
      else
          br.Canvas.Pixels[I, J] := clBlack;
      if green > TrackBarGreen.Position then
          bg.Canvas.Pixels[I, J] := clGreen
      else
          bg.Canvas.Pixels[I, J] := clBlack;
      if blue > TrackBarBlue.Position then
          bb.Canvas.Pixels[I, J] := clBlue
      else
          bb.Canvas.Pixels[I, J] := clBlack;
    end;
  br.SaveToFile('red.bmp');
  bg.SaveToFile('green.bmp');
  bb.SaveToFile('blue.bmp');
  br.Free;
  bg.Free;
  bb.Free;
end;

procedure TFormMain.ButtonColorResetClick(Sender: TObject);
begin
  TrackBarRed.Position := 128;
  TrackBarGreen.Position := 128;
  TrackBarBlue.Position := 128;
end;

procedure TFormMain.ButtonLoadClick(Sender: TObject);
begin
//  OpenDialog.Filter := 'Bitmap|*.bmp';
  if OpenPictureDialog1.Execute = True then
    if FileExists(OpenPictureDialog1.FileName) then
    begin
      PicFile := OpenPictureDialog1.FileName;
      ImagePic.Picture.LoadFromFile(OpenPictureDialog1.FileName);
      LabelSize.Caption := Format('Size:%d x %d',
            [ImagePic.Picture.Width, ImagePic.Picture.Height]
            );
    end;
end;

procedure TFormMain.BtnLoadFileClick(Sender: TObject);
begin
  OpenDialog.Filter := 'All Files|*.*';
  if OpenDialog.Execute = True then
    if FileExists(OpenDialog.FileName) then
    begin
      EditFile.Text := OpenDialog.FileName;
    end;
end;

procedure TFormMain.ButtonMakeClick(Sender: TObject);
var
  MifFilered: TextFile;
  MifFilegreen: TextFile;
  MifFileblue: TextFile;
  PicSource: TBitmap;
  PicCanvas: TCanvas;
  FileName: string;

  blue, green, red: Integer;
  color: TColor;
  i: Integer;
  j: Integer;
  counter: Integer;
  content: string;

  charwhite: Char;
  charblack: Char;
begin
  if PicFile = '' then
  begin
    Application.MessageBox('请先选择图像文件.', 'Pic2Mif');
  end else if SaveDialog.Execute = True then
  begin
    PicSource := TBitmap.Create();
    PicSource.LoadFromFile(PicFile);

    PicCanvas := PicSource.Canvas;
    {$I-}
    if RadioButtonTypeBlack.Checked = True then
    begin
      FileName := SaveDialog.FileName;
      AssignFile(MifFilered, FileName);
      Rewrite(MifFilered);

      Writeln(MifFilered, COPYRIGHT);
      Writeln(MifFilered, '');

      Writeln(MifFilered, 'WIDTH=' + '1' + ';');
      Writeln(MifFilered, 'DEPTH=' + IntToStr(PicSource.Width * PicSource.Height) + ';');
      Writeln(MifFilered, '');

      Writeln(MifFilered, 'ADDRESS_RADIX=UNS;');
      Writeln(MifFilered, 'DATA_RADIX=BIN;');
      Writeln(MifFilered, '');

      Writeln(MifFilered, 'CONTENT BEGIN');

      counter := 0;
      if RadioButtonBlack.Checked = True then
      begin
        charblack := '1';
        charwhite := '0';
      end else if RadioButtonWhite.Checked = True then
      begin
        charwhite := '1';
        charblack := '0';
      end;

      for i := 0 to PicSource.Height - 1 do
        for j := 0 to PicSource.Width - 1 do
        begin
          color := PicCanvas.Pixels[j, i];
          blue := (color and $00FF0000) shr 16;
          green := (color and ($0000FF00)) shr 8;
          red := color and $000000FF;

          if (blue <= TrackBarBlue.Position) and
            (green <= TrackBarGreen.Position) and
            (red <= TrackBarRed.Position) then
            Writeln(MifFilered, #09 + IntToStr(counter) + ' : ' + charblack + ';')
          else
            Writeln(MifFilered, #09 + IntToStr(counter) + ' : ' + charwhite + ';');

          Inc(counter);
        end;

      Writeln(MifFilered, 'END;');
      CloseFile(MifFilered);


    end else if RadioButtonTypeColor.Checked = True then
    begin
      FileName :=  SaveDialog.FileName;
      if RadioButtonColorSingle.Checked = True then
      begin
        AssignFile(MifFilered, FileName);
        Rewrite(MifFilered);

        Writeln(MifFilered, COPYRIGHT);
        Writeln(MifFilered, '');

        Writeln(MifFilered, 'WIDTH=' + '3' + ';');
        Writeln(MifFilered, 'DEPTH=' + IntToStr(PicSource.Width * PicSource.Height) + ';');
        Writeln(MifFilered, '');

        Writeln(MifFilered, 'ADDRESS_RADIX=UNS;');
        Writeln(MifFilered, 'DATA_RADIX=BIN;');
        Writeln(MifFilered, '');

        Writeln(MifFilered, 'CONTENT BEGIN');

        counter := 0;
        for i := 0 to PicSource.Height - 1 do
          for j := 0 to PicSource.Width - 1 do
          begin
            color := PicCanvas.Pixels[j, i];
            blue := (color and $00FF0000) shr 16;
            green := (color and ($0000FF00)) shr 8;
            red := color and $000000FF;

            if red >= TrackBarRed.Position then
              content := '1'
            else
              content := '0';

            if green >= TrackBarGreen.Position then
              content := content + '1'
            else
              content := content + '0';

            if blue >= TrackBarBlue.Position then
              content := content + '1'
            else
              content := content + '0';

            Writeln(MifFilered, #09 + IntToStr(counter) + ' : ' + content + ';');

            Inc(counter);
          end;

        Writeln(MifFilered, 'END;');
        CloseFile(MifFilered);

      end else if RadioButtonColorMultiple.Checked = True then
      begin
        AssignFile(MifFilered, FileName + '.red.mif');
        AssignFile(MifFilegreen, FileName + '.green.mif');
        AssignFile(MifFileblue, FileName + '.blue.mif');
        Rewrite(MifFilered);
        Rewrite(MifFilegreen);
        Rewrite(MifFileblue);

        Writeln(MifFilered, COPYRIGHT);
        Writeln(MifFilegreen, COPYRIGHT);
        Writeln(MifFileblue, COPYRIGHT);

        Writeln(MifFilered, 'WIDTH=' + '1' + ';');
        Writeln(MifFilered, 'DEPTH=' + IntToStr(PicSource.Width * PicSource.Height) + ';');
        Writeln(MifFilered, '');
        Writeln(MifFilegreen, 'WIDTH=' + '1' + ';');
        Writeln(MifFilegreen, 'DEPTH=' + IntToStr(PicSource.Width * PicSource.Height) + ';');
        Writeln(MifFilegreen, '');
        Writeln(MifFileblue, 'WIDTH=' + '1' + ';');
        Writeln(MifFileblue, 'DEPTH=' + IntToStr(PicSource.Width * PicSource.Height) + ';');
        Writeln(MifFileblue, '');

        Writeln(MifFilered, 'ADDRESS_RADIX=UNS;');
        Writeln(MifFilered, 'DATA_RADIX=BIN;');
        Writeln(MifFilered, '');
        Writeln(MifFilegreen, 'ADDRESS_RADIX=UNS;');
        Writeln(MifFilegreen, 'DATA_RADIX=BIN;');
        Writeln(MifFilegreen, '');
        Writeln(MifFileblue, 'ADDRESS_RADIX=UNS;');
        Writeln(MifFileblue, 'DATA_RADIX=BIN;');
        Writeln(MifFileblue, '');

        Writeln(MifFilered, 'CONTENT BEGIN');
        Writeln(MifFilegreen, 'CONTENT BEGIN');
        Writeln(MifFileblue, 'CONTENT BEGIN');

        counter := 0;
        for i := 0 to PicSource.Height - 1 do
          for j := 0 to PicSource.Width - 1 do
          begin
            color := PicCanvas.Pixels[j, i];
            blue := color shr 16;
            green := (color and ($0000FF00)) shr 8;
            red := color and $000000FF;

            if red >= TrackBarRed.Position then
              Writeln(MifFilered, #09 + IntToStr(counter) + ' : ' + '1' + ';')
            else
              Writeln(MifFilered, #09 + IntToStr(counter) + ' : ' + '0' + ';');
            if green >= TrackBarGreen.Position then
              Writeln(MifFilegreen, #09 + IntToStr(counter) + ' : ' + '1' + ';')
            else
              Writeln(MifFilegreen, #09 + IntToStr(counter) + ' : ' + '0' + ';');
            if blue >= TrackBarBlue.Position then
              Writeln(MifFileblue, #09 + IntToStr(counter) + ' : ' + '1' + ';')
            else
              Writeln(MifFileblue, #09 + IntToStr(counter) + ' : ' + '0' + ';');

            Inc(counter);
          end;

        Writeln(MifFilered, 'END;');
        Writeln(MifFilegreen, 'END;');
        Writeln(MifFileblue, 'END;');

        CloseFile(MifFilered);
        CloseFile(MifFilegreen);
        CloseFile(MifFileblue);
      end;
    {$I+}
      if (IOResult <> 0) then
        Application.MessageBox('读写文件出错。', 'PicToMif');
    end;

    PicSource.Free;

  end;
end;


procedure TFormMain.ButtonPreViewClick(Sender: TObject);
var
  PreViewCanvas: TCanvas;
  PicCanvas: TCanvas;
  W, H: Integer;
  WhiteC, BlackC: TColor;
  i, j: Integer;
  color: TColor;
  blue, green, red: Integer;
begin
  if ImagePic.Picture <> nil then
  begin
    FormPreView.ImagePreView.Picture.Bitmap.SetSize(ImagePic.Picture.Width, ImagePic.Picture.Height);
    W := FormPreView.ImagePreView.Width;
    H := FormPreView.ImagePreView.Height;

    PicCanvas := ImagePic.Picture.Bitmap.Canvas;
    PreViewCanvas := FormPreView.ImagePreView.Picture.Bitmap.Canvas;
    PreViewCanvas.Brush.Color := clBlack;
    PreViewCanvas.FillRect(Rect(0, 0, W, H));

    if RadioButtonTypeBlack.Checked = True then
    begin
      if RadioButtonBlack.Checked = True then
      begin
        BlackC := clWhite;
        WhiteC := clBlack;
      end else if RadioButtonWhite.Checked = True then
      begin
        BlackC := clBlack;
        WhiteC := clWhite;
      end;

      for i := 0 to H - 1 do
        for j := 0 to W - 1 do
        begin
          color := PicCanvas.Pixels[j, i];
          blue := (color and $00FF0000) shr 16;
          green := (color and ($0000FF00)) shr 8;
          red := color and $000000FF;

          if (blue <= TrackBarBlue.Position) and
            (green <= TrackBarGreen.Position) and
            (red <= TrackBarRed.Position) then
            PreViewCanvas.Pixels[j, i] := BlackC
          else
            PreViewCanvas.Pixels[j, i] := WhiteC;
        end;

    end else if RadioButtonTypeColor.Checked = True then
    begin
      for i := 0 to H - 1 do
        for j := 0 to W - 1 do
        begin
          color := PicCanvas.Pixels[j, i];
          blue := color shr 16;
          green := (color and ($0000FF00)) shr 8;
          red := color and $000000FF;

          color := 0;
          if red >= TrackBarRed.Position then
            color := color or $000000FF;
          if green >= TrackBarGreen.Position then
            color := color or $0000FF00;
          if blue >= TrackBarBlue.Position then
            color := color or $00FF0000;

          PreViewCanvas.Pixels[j, i] := color;
        end;
      end;
    end;

    FormPreView.Show;
end;

procedure TFormMain.A1Click(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TFormMain.btnBinToMifClick(Sender: TObject);
var
  Len: Integer;
begin
  mmoLog.Visible := False;
  if (not FileExists(EditFile.Text)) then
  begin
    ShowMessage('请确认源文件存在');
    Exit;
  end;
  Len := seLen.Value;
  if (Len <= 0) then
  begin
    ShowMessage('请输入字长');
    Exit;
  end;
  if (SaveDialog.Execute = True) then
  begin
      mmoLog.Lines.Clear;
      mmoLog.Lines.Add('Source    : ' + EditFile.Text);
      mmoLog.Lines.Add('Dest      : ' + SaveDialog.FileName);
      SaveBinaryToMif(EditFile.Text, Len, SaveDialog.FileName, mmoLog.Lines);
      if IOResult <> 0 then
      begin
        ShowMessage('读写文件出错');
      end else begin
      end;
      mmoLog.Visible := True;
  end;
end;

procedure TFormMain.EditRedGreenBlueChange(Sender: TObject);
var
  blue, green, red: Integer;
begin
  blue := StrToInt(EditBlue.Text);
  green := StrToInt(EditGreen.Text);
  red := StrToInt(EditRed.Text);

  PanelColor.Color := (blue shl 16) or (green shl 8) or red;
end;

procedure TFormMain.mExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.RadioButtonTypeBlackClick(Sender: TObject);
begin
  if RadioButtonTypeBlack.Checked = True then
  begin
    GroupBoxBlack.Visible := True;
    GroupBoxColor.Visible := False;
  end;
end;

procedure TFormMain.RadioButtonTypeColorClick(Sender: TObject);
begin
  if RadioButtonTypeColor.Checked = True then
  begin
    GroupBoxBlack.Visible := False;
    GroupBoxColor.Visible := True;
  end;
end;

procedure TFormMain.ScrollBoxPicDblClick(Sender: TObject);
begin
  if ColorDialog1.Execute then
  begin
    ScrollBoxPic.Color := ColorDialog1.Color;
  end;
end;

procedure TFormMain.TrackBarBlueChange(Sender: TObject);
begin
  EditBlue.Text := IntToStr(TrackBarBlue.Position);
end;

procedure TFormMain.TrackBarGreenChange(Sender: TObject);
begin
  EditGreen.Text := IntToStr(TrackBarGreen.Position);
end;

procedure TFormMain.TrackBarRedChange(Sender: TObject);
begin
  EditRed.Text := IntToStr(TrackBarRed.Position);
end;

end.
