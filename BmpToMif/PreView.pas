unit PreView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls;

type
  TFormPreView = class(TForm)
    ScrollBoxPreView: TScrollBox;
    ImagePreView: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormPreView: TFormPreView;

implementation

{$R *.dfm}

end.
