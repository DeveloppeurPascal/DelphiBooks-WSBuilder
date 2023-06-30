unit fBuildForm;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs, FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo;

type
  TfrmBuildForm = class(TForm)
    mmoLog: TMemo;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
    procedure log(ATxt: string);
    procedure Execute;
  end;

var
  frmBuildForm: TfrmBuildForm;

implementation

{$R *.fmx}

procedure TfrmBuildForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBuildForm.Execute;
begin
  // TODO : à compléter
  log('test before');
  sleep(2000);
  log('test after');
end;

procedure TfrmBuildForm.FormCreate(Sender: TObject);
begin
  mmoLog.lines.clear;
  btnClose.Enabled := false;
  try
    tthread.CreateAnonymousThread(
      procedure
      begin
        try
          Execute;
        finally
          tthread.Synchronize(nil,
            procedure
            begin
              btnClose.Enabled := true;
            end);
        end;
      end).start;
  except
    btnClose.Enabled := true;
    raise;
  end;
end;

procedure TfrmBuildForm.log(ATxt: string);
begin
  tthread.Synchronize(nil,
    procedure
    begin
      mmoLog.lines.add(ATxt);
      mmoLog.GoToTextEnd;
    end);
end;

end.
